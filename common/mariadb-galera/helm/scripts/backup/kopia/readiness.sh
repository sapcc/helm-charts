#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkkopiaserver {
  kopia server status \
  --address="http://${CONTAINER_IP}:${KOPIA_PORT}" \
  --server-control-username="${KOPIA_SERVER_CONTROL_USERNAME}" \
  --server-control-password="${KOPIA_SERVER_CONTROL_PASSWORD}" \
  --remote
  if [ $? -eq 0 ]; then
    echo 'Kopia server API reachable'
  else
    echo 'Kopia server API not reachable'
    exit 1
  fi
}

checkkopiaserver
