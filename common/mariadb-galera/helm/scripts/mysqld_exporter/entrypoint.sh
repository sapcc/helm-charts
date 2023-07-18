#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function startexporterink8s {
  loginfo "${FUNCNAME[0]}" "starting mysqld_exporter process"
  exec ${BASE}/bin/mysqld_exporter $(geteffectiveparametervalue)
}

startexporterink8s