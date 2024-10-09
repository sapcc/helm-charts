#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import shlex
import sys
from rabbitmq_setup_users import execute_command, get_target_users, \
    get_current_users, wait_until_rabbitmq_is_ready, read_config_file

RABBITMQ_CONFIGURATOR_CONFIG = "/etc/rabbitmq/configurator/config.ini"


def check_user_existance(current_users: set, target_users: set):
    if current_users == target_users:
        return True
    else:
        users_to_create = target_users - current_users
        if users_to_create:
            logging.error(f"READINESS PROBE: the following users are missing: {users_to_create}")
        users_to_delete = current_users - target_users
        if users_to_delete:
            logging.error(f"READINESS PROBE: the following users are present but should not be: {users_to_delete}")
        return False


def check_passwords(target_users: set[dict[str, str]]):
    for user in target_users:
        user_dict = dict(user)
        quoted_user = shlex.quote(user_dict['user'])
        quoted_password = shlex.quote(user_dict['password'])
        try:
            execute_command(f"rabbitmqctl authenticate_user -q {quoted_user} {quoted_password}")
        except Exception as e:
            logging.error(f"READINESS PROBE: Error while authenticating user {quoted_user}: {e}")
            return False
    return True


def main():
    logging.basicConfig(level=logging.INFO)
    KEEP_GUEST_USER = read_config_file(filepath=RABBITMQ_CONFIGURATOR_CONFIG, quiet=True)["keepguestuser"]
    logging.info("READINESS PROBE: Starting readiness probe")
    wait_until_rabbitmq_is_ready()
    target_users = get_target_users()
    target_usernames = [user[0][1] for user in target_users]
    if KEEP_GUEST_USER:
        target_usernames.append("guest")
    current_users = get_current_users()
    if check_user_existance(set(current_users), set(target_usernames)) and check_passwords(target_users):
        logging.info("READINESS PROBE: RabbitMQ configuration is ready")
        sys.exit(0)
    sys.exit(1)


if __name__ == "__main__":
    main()
