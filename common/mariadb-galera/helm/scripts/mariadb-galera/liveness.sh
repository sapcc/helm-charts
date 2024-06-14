#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkdbconnection {
  echo ''| socat TCP4-connect:${CONTAINER_IP}:${MYSQL_PORT} stdio | grep --binary-files=text MariaDB | grep --binary-files=text --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API reachable'
  else
    echo 'MariaDB MySQL API not reachable'
    exit 1
  fi
}

function checkgaleraport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds.database }} bash -c "</dev/tcp/${CONTAINER_IP}/${GALERA_PORT}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera API reachable'
  else
    echo 'MariaDB Galera API not reachable'
    exit 1
  fi
}

checkgaleraport
checkdbconnection
setconfigmap "running" "true" "Update"
