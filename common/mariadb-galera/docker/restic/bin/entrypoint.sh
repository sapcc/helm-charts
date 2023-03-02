#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

MAX_RETRIES=10
WAIT_SECONDS=6

function startrestic {
  loginfo "${FUNCNAME[0]}" "starting ping process in quiet mode"
  exec ping -4 -i 30 -n -q 127.0.0.1
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "ping startup failed"
    exit 1
  fi
}

startrestic
