#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function startkopiaserver {
  loginfo "${FUNCNAME[0]}" "starting kopia server process"
  exec kopia server start \
        --address="http://${CONTAINER_IP}:${KOPIA_PORT}" \
        --server-control-username="${KOPIA_SERVER_CONTROL_USERNAME}" \
        --server-control-password="${KOPIA_SERVER_CONTROL_PASSWORD}" \
        --ui-preferences-file=/opt/${SOFTWARE_NAME}/etc/ui.config.json \
        --no-legacy-api \
        --insecure \
        --ui
}

initkopiarepo
startkopiaserver
