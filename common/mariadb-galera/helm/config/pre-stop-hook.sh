#!/usr/bin/env bash
set +e
set -u
set -o pipefail

BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
MAX_RETRIES=10
WAIT_SECONDS=6

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y.%m.%d-%H:%M:%S-%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

function checkgaleralocalstate {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" | grep 'wsrep_local_state_comment' | grep --silent 'Synced'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node in sync with the cluster'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node not synced with the cluster'
    exit 1
  fi
}

function checkgaleraclusterstate {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_cluster_status';" | grep 'wsrep_cluster_status' | grep --silent 'Primary'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node reports a working cluster status'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node reports a not working cluster status'
    exit 1
  fi
}

function checkgaleranodeconnected {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_connected';" | grep 'wsrep_connected' | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node connected to other cluster nodes'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node not connected to other cluster nodes'
    exit 1
  fi
}

function shutdowngaleranode {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHUTDOWN WAIT FOR ALL SLAVES;"
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node shutdown successful'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node shutdown failed'
    exit 1
  fi
}

function lastmanstanding {
  local nodecount
  nodecount=$(mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --silent --skip-column-names --execute="SELECT node_name FROM mysql.wsrep_cluster_members ORDER BY node_name" | grep -c '{{ $.Release.Name }}-')
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node count check successful'
    if [ ${nodecount} -eq 1 ]; then
      touch ${DATADIR}/lastmanstanding
      if [ $? -eq 0 ]; then
        loginfo "${FUNCNAME[0]}" 'lastmanstanding file successfully created'
      else
        logerror "${FUNCNAME[0]}" 'lastmanstanding file creation failed'
        exit 1
      fi
    else
      loginfo "${FUNCNAME[0]}" 'more than one Galera node in the cluster. I am not the last man standing'
    fi
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node count check failed'
    exit 1
  fi
}

loginfo "null" "preStop hook started"
checkgaleraclusterstate
checkgaleranodeconnected
checkgaleralocalstate
#lastmanstanding
loginfo "null" "preStop hook done"
