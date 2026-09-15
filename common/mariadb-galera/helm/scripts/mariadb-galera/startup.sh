#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

timeout {{ $.Values.startupProbe.timeoutSeconds.database }} bash -c "</dev/tcp/${CONTAINER_IP}/${GALERA_PORT}"
if [ $? -eq 0 ]; then
  echo 'MariaDB Galera API reachable'
else
  echo 'MariaDB Galera API not reachable'
  exit 1
fi

mysql --protocol=socket --user=root --batch --connect-timeout={{ $.Values.startupProbe.timeoutSeconds.database }} --execute="SHOW DATABASES;" | grep --silent 'mysql'
if [ $? -eq 0 ]; then
  echo 'MariaDB MySQL API usable'
else
  echo 'MariaDB MySQL API not usable'
  exit 1
fi
