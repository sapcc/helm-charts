#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function backupgalera {
  loginfo "${FUNCNAME[0]}" "backup Galera cluster state and databases"

  cd /opt/${SOFTWARE_NAME}/tmp
  echo "ready ${CONTAINER_IP}:{{ (include "getNetworkPort" (dict "global" $ "type" "backend" "name" "galera") | int) }}"
  garbd --address {{ include "wsrepClusterAddress" (dict "global" $) | quote }} \
        --options "gmcast.listen_addr=tcp://${CONTAINER_IP}:{{ (include "getNetworkPort" (dict "global" $ "type" "backend" "name" "galera") | int) }};pc.recovery=FALSE" \
        --group {{ include "getEnvVar" (dict "global" $ "name" "MARIADB_CLUSTER_NAME") | quote }} \
        --sst galerabackup
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "backup failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "backup done"
}

backupgalera
