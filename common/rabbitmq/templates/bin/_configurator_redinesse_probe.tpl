#!/usr/bin/bash
# this script is used to check that rabbitmq is ready:
# all new users hae been created
# all unwanted users hae been removed

source /container.init/common_functions.sh

USERS_CONFIG="${ENV_RABBIT_USERCONFIG:-/config/users.yaml}"
USERS_TO_CREATE=$(cat $USERS_CONFIG | grep USERNAME | awk -F ':' '{print $2}' | tr -d '"')
CURRENT_USERS=$(rabbitmqctl list_users | grep -v "Listing users" | grep -v "tags" | awk '{print $1}')
# read options and ARGS
while getopts "c:t:" opt; do
  case $opt in
    c)
      USERS_CONFIG=$OPTARG
      ;;
    t)
      DELETE_TIMEOUT=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# check all users are created
for user in $USERS_TO_CREATE; do
  if [[ ! ${CURRENT_USERS[@]} =~ $user ]]; then
    echo "ERROR: not all users are created"
    exit 1
  fi
done
echo "All users are created"

# check all old users have been removed
for user in $CURRENT_USERS ; do
  if [[ ! ${USERS_TO_CREATE[@]} =~ $user ]]; then
    echo "ERROR: not all old users are deleted"
    exit 2
  fi
done
echo "All old users are deleted"

# check that all passwords have been updated
# by checking to login to rabbitmq using the last giving credentials
for user in $USERS_TO_CREATE; do
  PASSWORD_ = $(cat $USERS_CONFIG | grep "PASSWORD_$(getseq $USERS_CONFIG $user)" | awk -F ':' '{print $2}' | tr -d '"')
  if rabbitmqctl authenticate_user $user $PASSWORD_ ; then
    echo "ERROR: $user failed to authenticate with new password"
    exit 3
  fi
done
exit 0
