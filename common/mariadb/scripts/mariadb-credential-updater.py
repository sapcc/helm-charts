#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright 2025 SAP SE
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import time
import subprocess
import logging
import signal
import hashlib
import socket
import sys
import json
import datetime


class JsonFormatter(logging.Formatter):
    def format(self, record):
        return json.dumps(
            {
                "@timestamp": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+%Z"),
                "ecs.version": "1.6.0",
                "log.logger": "mariadb-credential-updater",
                "log.origin.function": record.funcName,
                "log.level": record.levelname.lower(),
                "message": record.getMessage(),
            }
        )


def setup_logging():
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logging.root.handlers = []
    logging.root.addHandler(handler)
    logging.root.setLevel(logging.INFO)


setup_logging()

INITDB_FILE_PATH = os.environ.get("INITDB_FILE_PATH", "/var/lib/initdb/init.sql")
CHECK_INTERVAL = int(os.environ.get("CHECK_INTERVAL", "10"))
MYSQL_ADDRESS = os.environ.get("MYSQL_ADDRESS", "/run/mysqld/mysqld.sock")
MYSQL_CLIENT_CONFIG = os.environ.get("MYSQL_CLIENT_CONFIG", "/root/.my.cnf")


def get_file_hash(file_path):
    """Calculate SHA256 hash of file content to detect changes"""
    try:
        with open(file_path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except Exception as e:
        return None


def check_socket_available():
    """Check if database socket file exists and is connectable"""
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(5)
            sock.connect(MYSQL_ADDRESS)
            return True
    except (socket.error, ValueError) as e:
        logging.error(f"Failed to connect to database socket: {str(e)}")
        return False


def check_db_readiness(timeout=5):
    """Check if database server is ready to accept SQL commands"""
    try:
        cmd = ["mariadb", f"--defaults-file={MYSQL_CLIENT_CONFIG}", "--skip-ssl", "mysql", "-e", "SELECT 1;"]

        logging.info("Testing database readiness")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)

        if result.returncode == 0:
            logging.info("Database server is ready to accept connections")
            return True
        else:
            logging.error(f"Database readiness check failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        logging.error("Database readiness check timed out")
        return False
    except Exception as e:
        logging.error(f"Failed database readiness check: {str(e)}")
        return False


def execute_sql(sql_file, max_retries=3, initial_wait=1.0):
    """Execute the SQL file using mariadb client with retries"""
    retries = 0
    wait_time = initial_wait
    success = False

    while retries <= max_retries and not success:
        try:
            cmd = [
                "mariadb",
                f"--defaults-file={MYSQL_CLIENT_CONFIG}",
                "--skip-ssl",
                "--batch",
                "-e",
                f"source {sql_file}",
            ]

            if retries > 0:
                logging.info(f"Retry attempt {retries}/{max_retries} for executing SQL file: {sql_file}")
            else:
                logging.info(f"Executing SQL file: {sql_file}")

            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                logging.info("SQL execution completed successfully")
                success = True
            else:
                logging.error(f"SQL execution failed with error: {result.stderr}")
                if retries < max_retries:
                    logging.info(f"Will retry in {wait_time:.1f} seconds")
                    time.sleep(wait_time)
                    wait_time = min(wait_time * 2, 30)
        except Exception as e:
            logging.error(f"Failed to execute SQL file: {str(e)}")
            if retries < max_retries:
                logging.info(f"Will retry in {wait_time:.1f} seconds")
                time.sleep(wait_time)
                wait_time = min(wait_time * 2, 30)

        retries += 1

    if not success:
        logging.error(f"SQL execution failed after {max_retries} retries")

    return success


def wait_for_db_readiness(max_retries=30, initial_wait=1.0):
    """Wait for the database server to be fully ready"""
    retries = 0
    is_ready = False
    wait_time = initial_wait

    logging.info(f"Waiting for database readiness at {MYSQL_ADDRESS}")

    while not is_ready and retries < max_retries:
        try:
            if check_socket_available():
                if check_db_readiness():
                    is_ready = True
                    logging.info(f"Database server is ready at {MYSQL_ADDRESS}")
                    break
                else:
                    logging.info("Database socket exists but database server is not yet ready")
        except socket.error as e:
            logging.error(f"Failed to connect to database socket: {str(e)}")

        retries += 1
        if not is_ready:
            wait_time = min(wait_time * 1.5, 10)
            logging.info(f"Waiting for database readiness... (attempt {retries}/{max_retries})")
            time.sleep(wait_time)

    if not is_ready:
        logging.error(f"Database not ready after {max_retries} attempts. Exiting.")
        return is_ready

    return is_ready


class SecretMonitor:
    def __init__(self, file_path):
        self.file_path = file_path
        self.last_content_hash = None
        self.running = False

    def setup_signal_handlers(self):
        signal.signal(signal.SIGINT, self.handle_shutdown)
        signal.signal(signal.SIGTERM, self.handle_shutdown)

    def handle_shutdown(self, signum, _):
        logging.info(f"Received signal {signum}, shutting down gracefully...")
        self.running = False

    def check_file(self):
        """Check if the file has changed"""
        if not os.path.exists(self.file_path):
            if self.last_content_hash is not None:
                logging.info(f"File no longer exists: {self.file_path}")
                self.last_content_hash = None
            return

        try:
            current_content_hash = get_file_hash(self.file_path)

            if self.last_content_hash is None and current_content_hash is not None:
                logging.info(f"New file detected: {self.file_path}")
                execute_sql(self.file_path)
                self.last_content_hash = current_content_hash
            elif current_content_hash != self.last_content_hash:
                logging.info(f"File content changed: {self.file_path}")
                execute_sql(self.file_path)
                self.last_content_hash = current_content_hash

        except FileNotFoundError:
            logging.error(f"File disappeared during processing: {self.file_path}")
            self.last_content_hash = None
        except PermissionError as e:
            logging.error(f"Permission denied accessing file: {str(e)}")
        except Exception as e:
            logging.error(f"Failed to check file: {str(e)}")

    def run(self):
        """Run the file monitor"""
        self.setup_signal_handlers()
        self.running = True

        logging.info(f"Started monitoring {self.file_path} for changes")

        while self.running:
            self.check_file()
            time.sleep(CHECK_INTERVAL)

        logging.info("File monitoring service has shut down")


def main():
    is_ready = wait_for_db_readiness()
    if not is_ready:
        sys.exit(1)

    monitor = SecretMonitor(INITDB_FILE_PATH)
    monitor.run()


if __name__ == "__main__":
    main()
