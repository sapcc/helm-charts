#!/usr/bin/bash
# this script is used to configure rabbitmqi users
# 1. create a list of users privided with -c option
# 2. configure all needed permisions on the users
# 3. it removes all other users gracefully (after all conncections of the user are closed)
#    deletion of the users failes after a timeout defined with option -t (default 60m)

source /container.init/common_functions.sh

USERS_CONFIG="${ENV_RABBIT_USERCONFIG:-/config/users.yaml}"
USERS_TO_CREATE=""
WORKER_PID=""
CONFIG_HASH=""
DELETE_TIMEOUT="${ENV_RABBIT_DELETETIMEOUT:-3600}"
DELETE_TRYS_INTERVAL="${ENV_RABBIT_DELETEINTERVALS:-5}"
WATCHDOG_INTERVAL="${ENV_RABBIT_WATCHDOGINTERVALS:-1}"
DELETE_GRACEFULLY="$ENV_RABBIT_DELETEGRECEFULLY:-false}"

# this function reads a user list provided in a yaml format
# generates a hash for the config and stores it in CONFIG_HASH
# config file looks like:
# USERNAME_01: $user
# PASSWORD_$user:  $password
init_config_session (){
  USERS_TO_CREATE=$(cat $USERS_CONFIG | grep USERNAME | awk -F ':' '{print $2}' | tr -d '"')
  CONFIG_HASH=$(md5sum $USERS_CONFIG | awk '{print $1}')
}

# this function creates a users from the list
create_users (){
  current_users=$(rabbitmqctl list_users | grep -v "Listing users" | awk '{print $1}')
  for user in $USERS_TO_CREATE; do
    if [[ ${current_users[@]} =~ $user ]]; then
      loginfo "${FUNCNAME[0]}" "User $user already exists, reset password"
      rabbitmqctl -q change_password $user $(cat $USERS_CONFIG | grep "PASSWORD_$(getseq $USERS_CONFIG $user)" | awk -F ':' '{print $2}' | tr -d '"')
      continue
    fi
    loginfo "${FUNCNAME[0]}" "Creating user $user"
    rabbitmqctl -q add_user $user $(cat $USERS_CONFIG | grep "PASSWORD_$(getseq $USERS_CONFIG $user)" | awk -F ':' '{print $2}' | tr -d '"')
  done
}

# this function sets permissions for the users
# it sets permissions for root vhosts
set_permissions (){
  for user in $USERS_TO_CREATE; do
    loginfo "${FUNCNAME[0]}" "Setting permissions for user $user"
    rabbitmqctl -q set_permissions -p / $user ".*" ".*" ".*"
  done
}

set_tags (){
  for user in $USERS_TO_CREATE; do
    loginfo "${FUNCNAME[0]}" "Setting tags for user $user"
    TAG=$(cat $USERS_CONFIG | grep "TAG_$(getseq $USERS_CONFIG $user)" | awk -F ':' '{print $2}' | tr -d '"')
    rabbitmqctl -q set_user_tags $user "${TAG:-openstack}"
  done
}

# this function removes one user and waits for all connections to be closed
remove_user (){
  # user=$1
  # TIMEOUT=$2
  # wait for all connections to be closed
  timeout --preserve-status $2 bash -c "while rabbitmqctl list_connections | grep $1 | grep running ; do  logdebug 'remove_user' 'user: $1 still habe open connections'; sleep $DELETE_TRIES_INTERVAL; done"
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "Timeout reached, not all connections of user $user are closed, or idle"
    # if DELETE_GRACEFULLY is set to true exit with exit code 1
    # if DELETE_GRACEFULLY is set to false force delete the user and exit with code 0
    if [ $DELETE_GRACEFULLY ]; then
      exit 1
    else
      loginfo "${FUNCNAME[0]}"  "Timeout reached,DELETE_GRACEFULLY is not set deleting user: $user"
    fi
  fi
  loginfo "${funcname[0]}" "$(rabbitmqctl delete_user $user)"
  loginfo "${funcname[0]}" " user: $user deleted successfully"
}

# this function removes all users except the ones provided in the list
# it retrieve current user and delete all user not in USERS_TO_CREATE list
remove_old_users (){
  #TIMEOUT=$1
  KIDs=()
  trap 'kill -TERM ${KIDs[@]} 2>/dev/null; logwarn "${FUNCNAME[0]}" "received a signal to kill all deleters"; wait; exit 1' TERM
  current_users=$(rabbitmqctl list_users | grep -v "Listing users" | grep -v "tags" | awk '{print $1}')
  for user in $current_users; do
    if [[ ! ${USERS_TO_CREATE[@]} =~ $user ]]; then
      remove_user $user $1 &
      KIDs+=($!)
    fi
  done
  wait
}

config_watchdog (){
  while true; do
    if [ $(md5sum $USERS_CONFIG | awk '{print $1}') != $CONFIG_HASH ]; then
      loginfo "${FUNCNAME[0]}" "Config file changed, restarting config session"
      if ps -p $WORKER_PID &> /dev/null ; then kill -TERM $WORKER_PID ; fi
      wait
      exit 0
    fi
    sleep $WATCHDOG_INTERVAL
  done
}


# Main-Loop
while getopts "c:t:" opt; do
  case $opt in
    c)
      USERS_CONFIG=$OPTARG
      ;;
    t)
      DELETE_TIMEOUT=$OPTARG
      ;;
    \?)
      logerror "${FUNCNAME[0]}" "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
sleep 30
while true; do
  init_config_session
  create_users
  set_permissions
  set_tags
  remove_old_users $DELETE_TIMEOUT &
  WORKER_PID=$!
  config_watchdog &
  WATCHDOG_PID=$!
  if wait $WATCHDOG_PID; then
    logdebug "Main-Loop" "######################## interrupted, triggering  new config Cycle ##############################"
    logdebug "Main-Loop" "re-initializing the worker after the configuration change"
  else
    logerror "Main-Loop" "watchdog subprocess failed"
  fi
done
