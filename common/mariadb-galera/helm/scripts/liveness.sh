#!/usr/bin/env bash
set +e
set -u
set -o pipefail

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}

source ${BASE}/bin/common-functions.sh

function checkdblogon {
  mysql --defaults-file=/opt/mariadb/etc/my.cnf --protocol=tcp --user=root --host=localhost --port=${MYSQL_PORT} --batch --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds.application }} --execute="SHOW DATABASES;" | grep --silent 'mysql'
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API reachable'
  else
    echo 'MariaDB MySQL API not reachable'
    exit 1
  fi
}

function checkgaleraport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds.application }} bash -c "</dev/tcp/${CONTAINER_IP}/${GALERA_PORT}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera API reachable'
  else
    echo 'MariaDB Galera API not reachable'
    exit 1
  fi
}

checkdblogon
checkgaleraport
setconfigmap "running" "true" "Update"
