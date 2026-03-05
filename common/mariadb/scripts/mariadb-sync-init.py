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

from __future__ import annotations

import json
import logging
import os
import shlex
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from typing import Callable

RETRY_ATTEMPTS = 5
RETRY_DELAY_SECONDS = 2
SLEEP_INTERVAL_SECONDS = 60
COMMAND_TIMEOUT_SECONDS = 30


class GracefulShutdown:
    """Handle graceful shutdown."""

    def __init__(self):
        self.shutdown_requested = False

    def setup_signal_handlers(self):
        """Setup signal handlers for graceful shutdown."""
        signal.signal(signal.SIGINT, self.handle_shutdown)
        signal.signal(signal.SIGTERM, self.handle_shutdown)

    def handle_shutdown(self, signum: int, _) -> None:
        """Handle shutdown signals gracefully."""
        logging.info(f"Received signal {signum}, shutting down gracefully...")
        self.shutdown_requested = True


shutdown_handler = GracefulShutdown()


class JsonFormatter(logging.Formatter):
    """JSON formatter for structured logging."""

    def format(self, record):
        return json.dumps(
            {
                "@timestamp": datetime.now(timezone.utc).isoformat() + "Z",
                "ecs.version": "1.6.0",
                "log.logger": "mariadb-sync-init",
                "log.origin.function": record.funcName,
                "log.level": record.levelname.lower(),
                "message": record.getMessage(),
            }
        )


def setup_logging():
    """Setup structured JSON logging."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logging.root.handlers = []
    logging.root.addHandler(handler)
    logging.root.setLevel(logging.INFO)


def log(msg: str) -> None:
    """Log message using structured logging."""
    logging.info(msg)


class MariaDBCLIError(RuntimeError):
    """Raised for mariadb CLI failures."""

    pass


def validate_environment() -> tuple[str, str, str, int]:
    """Validate required environment variables early. Returns (host, user, password, port)."""
    missing_vars = []

    host = os.getenv("TARGETDB_HOST")
    if not host:
        missing_vars.append("TARGETDB_HOST")

    user = os.getenv("TARGETDB_USER")
    if not user:
        missing_vars.append("TARGETDB_USER")

    password = os.getenv("TARGETDB_PASSWORD")
    if password is None:
        missing_vars.append("TARGETDB_PASSWORD")

    if missing_vars:
        raise MariaDBCLIError(
            f"Missing required environment variables: {', '.join(missing_vars)}. Please set them before running."
        )

    port_str = os.getenv("TARGETDB_PORT", "3306")
    try:
        port = int(port_str)
        if port <= 0 or port > 65535:
            raise ValueError("Port must be between 1 and 65535")
    except ValueError as e:
        raise MariaDBCLIError(f"Invalid TARGETDB_PORT '{port_str}': {e}") from e

    assert host is not None and user is not None and password is not None
    return host, user, password, port


def get_cli_cmd(host: str, user: str, port: int) -> list[str]:
    """Build MariaDB command line with validated parameters."""
    return [
        "mariadb",
        "--batch",
        "--skip-column-names",
        "--skip-ssl",
        f"--user={user}",
        f"--host={host}",
        f"--port={port}",
    ]


_db_config: tuple[str, str, str, int] | None = None


def get_db_config() -> tuple[str, str, str, int]:
    """Get validated database configuration."""
    global _db_config
    if _db_config is None:
        _db_config = validate_environment()
    return _db_config


def run_mariadb_cli(sql: str) -> str:
    """Execute SQL command via MariaDB CLI with proper error handling."""
    host, user, password, port = get_db_config()
    base = get_cli_cmd(host, user, port)
    full_cmd = base + ["-e", sql]
    logging.info(f"Executing: mariadb -e {shlex.quote(sql)}")

    try:
        env = os.environ.copy()
        env["MYSQL_PWD"] = password
        result = subprocess.run(
            full_cmd, env=env, capture_output=True, text=True, timeout=COMMAND_TIMEOUT_SECONDS, check=True
        )
        return result.stdout.strip()
    except subprocess.TimeoutExpired as e:
        raise MariaDBCLIError(
            f"MariaDB command timed out after {COMMAND_TIMEOUT_SECONDS} seconds. Check network connectivity."
        ) from e
    except subprocess.CalledProcessError as e:
        raise MariaDBCLIError(f"mariadb command failed (exit {e.returncode}): {e.stderr or e.stdout}") from e


def ensure_database_and_table() -> None:
    """Create replication database and stamp table if they don't exist."""
    run_mariadb_cli("CREATE DATABASE IF NOT EXISTS replication")
    run_mariadb_cli(
        "CREATE TABLE IF NOT EXISTS replication.stamp (\n"
        "  id INT PRIMARY KEY NOT NULL DEFAULT 1,\n"
        "  timestamp DATETIME NOT NULL\n"
        ") ENGINE=InnoDB"
    )


def test_connection() -> None:
    """Test database connectivity with a simple query."""
    run_mariadb_cli("SELECT 1")


def wait_for_db_readiness(max_retries: int = 30, initial_wait: float = 1.0) -> bool:
    """Wait for the database server to be ready."""
    retries = 0
    is_ready = False
    wait_time = initial_wait

    host, _, _, port = get_db_config()
    logging.info(f"Waiting for database readiness at {host}:{port}")

    while not is_ready and retries < max_retries:
        try:
            test_connection()
            is_ready = True
            logging.info(f"Database server is ready at {host}:{port}")

        except MariaDBCLIError as e:
            retries += 1
            if retries < max_retries:
                wait_time = min(wait_time * 1.5, 10)
                logging.info(f"Database not ready... (attempt {retries}/{max_retries}): {e}")
                time.sleep(wait_time)
            else:
                logging.error(f"Database not ready after {max_retries} attempts: {e}")

    return is_ready


def stamp(timestamp: datetime) -> None:
    """Insert or update the replication timestamp stamp."""
    formatted_timestamp = timestamp.strftime("%Y-%m-%d %H:%M:%S")
    run_mariadb_cli(f"REPLACE INTO replication.stamp (id, timestamp) VALUES (1, '{formatted_timestamp}')")


def get_timestamp() -> str | None:
    """Retrieve the existing replication timestamp stamp if present."""
    try:
        result = run_mariadb_cli("SELECT timestamp FROM replication.stamp WHERE id=1")
        return result or None
    except MariaDBCLIError as e:
        error_msg = str(e).lower()

        if any(code in error_msg for code in ["1146", "42s02"]):  # Table doesn't exist
            logging.info("Replication table doesn't exist yet - no existing stamp found")
            return None
        if any(code in error_msg for code in ["1049", "42000"]):  # Database doesn't exist
            logging.info("Replication database doesn't exist yet - no existing stamp found")
            return None

        raise


def main() -> int:
    setup_logging()
    shutdown_handler.setup_signal_handlers()

    if not shutil.which("mariadb"):
        logging.error("MariaDB client 'mariadb' not found in PATH. Please install mariadb-client package.")
        return 2

    try:
        host, user, _, port = get_db_config()
        logging.info(f"Configuration validated. Connecting to {host}:{port} as user '{user}'")
    except MariaDBCLIError as e:
        logging.error(f"Configuration validation failed: {e}")
        return 10

    if not wait_for_db_readiness(max_retries=30, initial_wait=1.0):
        logging.error("Database not ready. Exiting.")
        return 10

    try:
        existing_timestamp = get_timestamp()
    except MariaDBCLIError as e:
        logging.error(f"Error checking existing stamp: {e}")
        logging.info("Assuming no existing stamp and proceeding with initialization.")
        existing_timestamp = None

    if existing_timestamp:
        logging.info(
            f"Replication stamp already exists (timestamp={existing_timestamp}). "
            "Blocking pod initialization to prevent further changes."
        )
        try:
            while not shutdown_handler.shutdown_requested:
                time.sleep(SLEEP_INTERVAL_SECONDS)
            logging.info("Shutdown requested during blocking phase. Exiting gracefully.")
        except KeyboardInterrupt:
            logging.info("Interrupt received; exiting.")
        return 0

    current_timestamp = datetime.now(timezone.utc).replace(microsecond=0)
    try:
        logging.info("Creating replication database and table...")
        retry(
            ensure_database_and_table, attempts=RETRY_ATTEMPTS, delay=RETRY_DELAY_SECONDS, what="create database/table"
        )

        logging.info(f"Inserting replication stamp with timestamp {current_timestamp}...")
        retry(lambda: stamp(current_timestamp), attempts=RETRY_ATTEMPTS, delay=RETRY_DELAY_SECONDS, what="insert stamp")

    except MariaDBCLIError as e:
        logging.error(f"Error creating replication stamp: {e}")
        return 10

    formatted_timestamp = current_timestamp.strftime("%Y-%m-%d %H:%M:%S")
    logging.info(
        f"Successfully created replication stamp (timestamp={formatted_timestamp}). Pod initialization can proceed."
    )
    return 0


def retry(fn: Callable[[], None], *, attempts: int, delay: int, what: str) -> None:
    """Retry function with exponential backoff."""
    retries = 0
    wait_time = float(delay)
    success = False

    while retries < attempts and not success:
        try:
            if retries > 0:
                logging.info(f"Retry attempt {retries}/{attempts} for {what}")
            else:
                logging.info(f"Attempting to {what}")

            fn()
            success = True
            if retries > 0:
                logging.info(f"Succeeded to {what} on attempt {retries + 1}")

        except MariaDBCLIError as e:
            if retries >= attempts:
                logging.error(f"{what} failed after {attempts} retries")
                raise

            error_msg = str(e).lower()
            is_transient = any(term in error_msg for term in ["connection", "timeout", "network", "temporary"])

            if is_transient:
                logging.error(f"Attempt {retries + 1}/{attempts + 1} failed for {what} (transient error): {e}")
                logging.info(f"Will retry in {wait_time:.1f} seconds")
                time.sleep(wait_time)
                wait_time = min(wait_time * 2, 30)
            else:
                logging.error(f"Attempt {retries + 1}/{attempts + 1} failed for {what} (non-transient error): {e}")
                logging.info(f"Will retry in {delay} seconds")
                time.sleep(delay)

        retries += 1


if __name__ == "__main__":
    sys.exit(main())
