#!/usr/bin/env bash
set +e
set -u
set -o pipefail

BASE=/opt/${SOFTWARE_NAME}
MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}

source ${BASE}/bin/common-functions.sh

function startexporterink8s {
  loginfo "${FUNCNAME[0]}" "starting mysqld_exporter process"
  exec ${BASE}/bin/mysqld_exporter $(geteffectiveparametervalue)
}

startexporterink8s