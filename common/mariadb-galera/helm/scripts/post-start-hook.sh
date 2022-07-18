#!/usr/bin/env bash
set +e
set -u
set -o pipefail

BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
MAX_RETRIES={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y.%m.%d-%H:%M:%S-%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

loginfo "null" "postStart hook started"
loginfo "null" "postStart hook done"
