#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkkopiaserverport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds.kopiaserver }} bash -c "</dev/tcp/${CONTAINER_IP}/${KOPIA_PORT}"
  if [ $? -eq 0 ]; then
    echo 'Kopia server API reachable'
  else
    echo 'Kopia server API not reachable'
    exit 1
  fi
}

checkkopiaserverport
