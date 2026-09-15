#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

MAX_RETRIES=10
WAIT_SECONDS=6

function startkopiaserver {
  loginfo "${FUNCNAME[0]}" "starting kopia server process"
  exec kopia server start http://${CONTAINER_IP}:${KOPIA_PORT} \
        --cache-directory=${KOPIA_CACHE_DIR} \
        --check-for-updates=false \
        --control-api=false --grpc=false --legacy-api=false \
        --enable-actions=false \
        --server-username=${KOPIA_ADMIN_USERNAME} --server-password=${KOPIA_ADMIN_PASSWORD} \
        --ui-preferences-file=/opt/${SOFTWARE_NAME}/etc/ui.config.json \
        --config-file=/opt/${SOFTWARE_NAME}/etc/repository.config \
        --insecure=true \
        --ui=true
}

startkopiaserver
