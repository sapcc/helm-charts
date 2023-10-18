#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkproxybackendport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds.database }} bash -c "</dev/tcp/${CONTAINER_IP}/${PROXYSQL_ADMIN_PORT}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera API reachable'
  else
    echo 'MariaDB Galera API not reachable'
    exit 1
  fi
}

function checkproxybackendlogon {
  mysql --protocol=tcp --user=${PROXYSQL_ADMIN_USERNAME} --password=${PROXYSQL_ADMIN_PASSWORD} --host=localhost --port=${PROXYSQL_ADMIN_PORT} --prompt='Admin> ' --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds.proxy }} --wait --reconnect --batch --execute="SHOW DATABASES;" | grep --silent '/opt/proxysql/data/proxysql.db'
  if [ $? -eq 0 ]; then
    echo 'ProxySQL API reachable'
  else
    echo 'ProxySQL API not reachable'
    exit 1
  fi
}

checkproxybackendport
checkproxybackendlogon
