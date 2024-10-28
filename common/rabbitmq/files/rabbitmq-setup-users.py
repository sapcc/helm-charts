#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import glob
import json
import logging
import os
import shlex
import subprocess
from typing import List, Dict

SECRETS_PATH = "/etc/rabbitmq/secrets"
DEFAULT_PERMISSIONS = '".*" ".*" ".*"'


def read_file(filepath: str) -> str:
    try:
        with open(filepath, "r") as file:
            return file.read().strip()
    except IOError as e:
        logging.error(f"Error reading file {filepath}: {e}")
        return ""


def execute_command(command: str) -> str:
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed: {e}")
        raise


def get_target_users() -> List[Dict[str, str]]:
    target_users = []
    for username_file in glob.glob(os.path.join(SECRETS_PATH, "user_*_username")):
        password_file = username_file.replace("_username", "_password")
        tag_file = username_file.replace("_username", "_tag")

        username = read_file(username_file)
        password = read_file(password_file) if os.path.exists(password_file) else ""
        tag = read_file(tag_file) if os.path.exists(tag_file) else ""

        target_users.append({"user": username, "password": password, "tag": tag})
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
        logging.error(f"Failed to manage user {username}: {e}")


def main():
    logging.basicConfig(level=logging.INFO)

    target_users = get_target_users()
    current_users = get_current_users()

    for user in target_users:
        manage_user(user["user"], user["password"], user["tag"], current_users)

    execute_command("rabbitmqctl clear_password guest")


if __name__ == "__main__":
    main()
