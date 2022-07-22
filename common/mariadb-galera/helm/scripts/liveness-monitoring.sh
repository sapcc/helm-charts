#!/usr/bin/env bash
set +e
set -u
set -o pipefail

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}

source ${BASE}/bin/common-functions.sh

function checkmysqlexporterport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds.monitoring }} bash -c "</dev/tcp/${CONTAINER_IP}/${WEB_LISTEN_PORT}"
  if [ $? -eq 0 ]; then
    echo 'MySQL export HTTP port reachable'
  else
    echo 'MySQL export HTTP port not reachable'
    exit 1
  fi
}

checkmysqlexporterport
