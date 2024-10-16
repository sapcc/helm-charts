#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import hashlib
import glob
import json
import logging
import os
import shlex
import signal
import subprocess
import time
from configparser import ConfigParser
from functools import partial
from multiprocessing import Process
from multiprocessing import Pool
from typing import List, Dict

SECRETS_PATH = "/etc/rabbitmq/secrets"
RABBITMQ_CONFIGURATOR_CONFIG = "/etc/rabbitmq/configurator/config.ini"
DEFAULT_PERMISSIONS = '".*" ".*" ".*"'
DELETION_TIMEOUT = 180
RABBITMQ_TIMEOUT = 60
DELETION_FORCE_TYPE = "force"
KEEP_GUEST_USER = True
WATCHDOG_INTERVAL = 5


def read_file(filepath: str) -> str:
    try:
        with open(filepath, "r") as file:
            return file.read().strip()
    except IOError as e:
        logging.error(f"READ FILE: Error reading file {filepath}: {e}")
        return ""


def read_config_file(filepath: str, quiet: bool = False) -> Dict[str, str]:
    global SECRETS_PATH, \
        DEFAULT_PERMISSIONS, \
        DELETION_TIMEOUT, \
        RABBITMQ_TIMEOUT, \
        DELETION_FORCE_TYPE, \
        KEEP_GUEST_USER, \
        WATCHDOG_INTERVAL
    try:
        parser = ConfigParser()
        parser.read(filepath)
        if 'main' in parser:
            if parser['main'].get('deletionTimeout'):
                DELETION_TIMEOUT = parser['main']['deletionTimeout']
            if parser['main'].get('rabbitmqTimeout'):
                RABBITMQ_TIMEOUT = parser['main']['rabbitmqTimeout']
            if parser['main'].get('deletionForeType'):
                DELETION_FORCE_TYPE = parser['main']['deletionForeType']
            if parser['main'].get('keepGuestUser'):
                KEEP_GUEST_USER = parser['main']['keepGuestUser']
            if parser['main'].get('watchDogInterval'):
                WATCHDOG_INTERVAL = parser['main']['watchDogInterval']
            if not quiet:
                for item in parser['main']:
                    logging.info(f"READ CONFIG FILE: {item} = {parser['main'][item]}")
            return dict(parser.items('main'))
    except IOError as e:
        logging.error(f"READ CONFIG FILE: Error reading file {filepath}: {e}")
        return {}


def execute_command(command: str, log: bool = True) -> str:
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError as e:
        if log:
            logging.error(f"Command failed: {e}")
        raise


def get_target_users() -> set[Dict[str, str]]:
    target_users = set()
    for username_file in glob.glob(os.path.join(SECRETS_PATH, "user_*_username")):
        password_file = username_file.replace("_username", "_password")
        tag_file = username_file.replace("_username", "_tag")

        username = read_file(username_file)
        password = read_file(password_file) if os.path.exists(password_file) else ""
        tag = read_file(tag_file) if os.path.exists(tag_file) else ""
        target_users.add(tuple({"user": username, "password": password, "tag": tag}.items()))
    return target_users


def get_current_users() -> List[str]:
    result = subprocess.run(
        ["rabbitmqctl", "list_users", "--quiet", "--formatter=json"], capture_output=True, text=True, check=True
    )
    current_users = json.loads(result.stdout)
    return [user_dict["user"] for user_dict in current_users]


def manage_user(username: str, password: str, tag: str, current_users: List[str]) -> None:
    try:
        username_quoted = shlex.quote(username)
        password_quoted = shlex.quote(password)
        tag_quoted = shlex.quote(tag)

        if username in current_users:
            execute_command(f"rabbitmqctl change_password {username_quoted} {password_quoted}")
            execute_command(f"rabbitmqctl set_user_tags {username_quoted} {tag_quoted}")
        else:
            execute_command(f"rabbitmqctl add_user {username_quoted} {password_quoted}")
            execute_command(f"rabbitmqctl set_permissions -q {username_quoted} {DEFAULT_PERMISSIONS}")
            execute_command(f"rabbitmqctl set_user_tags {username_quoted} {tag_quoted}")
    except subprocess.CalledProcessError as e:
        logging.error(f"MANAGE USER: Failed to manage user {username}: {e}")


def delete_user(username: str, force_type: str, timeout: int = DELETION_TIMEOUT):
    username_quoted = shlex.quote(username)
    ready_to_delete = False
    logging.info(f"DELETE USER: Deleting user {username} with force type {force_type}")
    if force_type != "force":
        # wait for all connections to be closed before force deleting the user or fail after
        # `rabbitmqctl list_connections | grep -q $username` lists open connection of a user
        until = time.time() + timeout
        while time.time() < until:
            try:
                logging.info(f"DELETE USER: waiting for connections to be closed for user {username}")
                execute_command(f"rabbitmqctl list_connections | grep -q {username_quoted}", log=False)
            except subprocess.CalledProcessError:
                logging.info(f"DELETE USER: connections are closed for user {username}")
                ready_to_delete = True
                break
            time.sleep(2)
        logging.info(f"DELETE USER: stopped waiting for connections to be closed for user {username}")
    if force_type == "gracefully":
        if ready_to_delete:
            execute_command(f"rabbitmqctl delete_user {username_quoted}")
            logging.info(f"DELETE USER: user {username} has been deleted")
            return 0
        else:
            # fail because the connections are not closed
            logging.error(f"DELETE USER: Failed to delete user {username} gracefully: Many connections are still open")
            return 1
    elif force_type == "force" or force_type == "force_gracefully":
        # force delete the user
        execute_command(f"rabbitmqctl delete_user {username_quoted}")
        logging.info(f"DELETE USER: user {username} has been deleted")
        return 0
    else:
        # fail because the force type is invalid
        logging.error(f"""DELETE USER: Failed to delete user {username}: Invalid force type must be:
                        [force|force_gracefully|gracefully] got {force_type}""")
        return 2


def get_md5_hash(filepath: str) -> str:
    try:
        with open(filepath, "rb") as file:
            return hashlib.md5(file.read()).hexdigest()
    except IOError as e:
        logging.error(f"GET MD5 HASH: Error reading file {filepath}: {e}")
        return


def watch_dog(intervals: int = WATCHDOG_INTERVAL):
    target_users = get_target_users()
    prev_config_hash = get_md5_hash(RABBITMQ_CONFIGURATOR_CONFIG)
    logging.info("WATCH DOG: Started ....")
    while True:
        if prev_config_hash != get_md5_hash(RABBITMQ_CONFIGURATOR_CONFIG):
            logging.info("WATCH DOG: Config file has been updated exiting watchdog")
            return
        new_target_users = get_target_users()
        if target_users != new_target_users:
            logging.info("WATCH DOG: Users have been updated exiting watchdog")
            return
        time.sleep(intervals)


# this function remove all unwanted users from rabbitmq
# it forkes a new process for each user and return once all sub oprocesses are done
# it return 0 if all users are deleted successfully
# it return 1 if any user failed to delete
def delete_unwanted_users(current_users: List[str],
                          target_users: set[tuple[str, str]],
                          force_type: str = DELETION_FORCE_TYPE,
                          keep_guest_user: bool = KEEP_GUEST_USER):
    users_to_delete = []
    target_usernames = [user[0][1] for user in target_users]
    if keep_guest_user:
        target_usernames.append("guest")
    logging.info("DELETE UNWANTED USERS: Searching for unwanted users")
    for user in current_users:
        if user in target_usernames:
            logging.info(f"DELETE UNWANTED USERS: {user} still needed")
        else:
            users_to_delete.append(user)
            logging.info(f"DELETE UNWANTED USERS: Found {user} to be deleted")
    if users_to_delete:
        with Pool() as pool:
            signal.signal(signal.SIGTERM, partial(kill_deletion_process, worker=pool))
            try:
                results = pool.map(partial(delete_user, force_type=force_type), users_to_delete)
                return 1 if any(results) else 0
            except Exception as e:
                if str(e) == "Killed by external signal":
                    logging.info("DELETE UNWANTED USERS: User deletion process was interrupted")


def kill_deletion_process(signum, frame, worker: Pool):
    worker.terminate()
    logging.info("KILL DELETE PROCESS HANDLER: User deletion process was interrupted")
    raise Exception("Killed by external signal")


def wait_until_rabbitmq_is_ready(timeout: int = RABBITMQ_TIMEOUT) -> None:
    logging.info("WAITING FOR RABBITMQ: waiting for Rabbitmq to be up an running")
    until = time.time() + timeout
    while time.time() < until:
        try:
            execute_command("rabbitmqctl status > /dev/null 2>&1", log=False)
            time.sleep(5)
            logging.info("WAITING FOR RABBITMQ: Rabbitmq is up an running")
            return
        except subprocess.CalledProcessError:
            logging.error("WAITING FOR RABBITMQ: Rabbitmq is not ready yet, retrying in 1 seconds...")
        time.sleep(1)
    logging.error("WAITING FOR RABBITMQ: Failed to get rabbitmq status after", timeout, "seconds")
    exit(1)


def main():
    logging.basicConfig(level=logging.INFO)
    wait_until_rabbitmq_is_ready()
    logging.info("MAIN: Reading configurator config file")
    read_config_file(RABBITMQ_CONFIGURATOR_CONFIG)
    if KEEP_GUEST_USER:
        execute_command("rabbitmqctl clear_password guest")

    # start the mail loop and wait for the watchdog to exit
    while True:
        logging.info("MAIN LOOP: Starting new config cycle")
        target_users = get_target_users()
        current_users = get_current_users()
        for user in target_users:
            user_dict = dict(user)
            logging.info("MAIN LOOP: call  manage user:" + str(user_dict["user"]))
            manage_user(user_dict["user"], user_dict["password"], user_dict["tag"], current_users)
        current_users = get_current_users()
        logging.info("MAIN LOOP: fork deleting unwanted users subprocess")
        deleteProcess = Process(target=delete_unwanted_users, args=(current_users, target_users))
        deleteProcess.start()
        logging.info("MAIN LOOP: deleting process has been forked")
        logging.info("MAIN LOOP: Starting watchdog")
        watchdogProcess = Process(target=watch_dog)
        watchdogProcess.start()
        watchdogProcess.join()
        logging.info("MAIN LOOP: watch dog has exited, terminating user deletion process...")
        deleteProcess.terminate()
        logging.info("MAIN LOOP: User deletion process has been terminated")
        logging.info("MAIN LOOP: Reading configurator config file")
        read_config_file(RABBITMQ_CONFIGURATOR_CONFIG)


if __name__ == "__main__":
    main()
