#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

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
