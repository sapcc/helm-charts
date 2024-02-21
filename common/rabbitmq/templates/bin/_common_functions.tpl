#!/usr/bin/bash
#this is shared functions with you can source in your script and use its functions

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y-%m-%dT%H:%M:%S+%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logwarn {
  logjson "stdout" "warning" "$0" "$1" "$2"
}

function logdebug {
  logjson "stdout" "debug" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

function getseq {
  USERS_CONFIG=$1
  USERNAME=$2
  echo "$(cat $USERS_CONFIG | grep USERNAME | grep $USERNAME | awk -F ':' '{print $1}' | tr -d '"' | tr -d "USERNAME_")"
}
