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

function setuprootuser {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    checkdbk8sservicelogon "true"
    if [ $? -eq 0 ]; then
      break
    else
      loginfo "${FUNCNAME[0]}" "database not yet usable. Will wait ${WAIT_SECONDS}s before retry"
      sleep ${WAIT_SECONDS}
    fi
  done

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "setup root user permissions(${int} retries left)"
    cat ${BASE}/etc/sql/root_permissions.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=mariadb-galera-fe.database.svc.cluster.local --port=${MYSQL_PORT} --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "root user setup has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "root user setup has been finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "root user setup done"
}

function setupmonitoringuser {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    checkdbk8sservicelogon "true"
    if [ $? -eq 0 ]; then
      break
    else
      loginfo "${FUNCNAME[0]}" "database not yet usable. Will wait ${WAIT_SECONDS}s before retry"
      sleep ${WAIT_SECONDS}
    fi
  done

  if [ -f "${BASE}/etc/sql/monitoring_permissions.sql.tpl" ] && [ -n ${MARIADB_MONITORING_USER+x} ] && [ -n ${MARIADB_MONITORING_PASSWORD+x} ]; then
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      loginfo "${FUNCNAME[0]}" "setup monitoring user permissions(${int} retries left)"
      cat ${BASE}/etc/sql/monitoring_permissions.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=mariadb-galera-fe.database.svc.cluster.local --port=${MYSQL_PORT} --batch
      if [ $? -ne 0 ]; then
        logerror "${FUNCNAME[0]}" "monitoring user setup has been failed"
        sleep ${WAIT_SECONDS}
      else
        break
      fi
    done
    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "monitoring user setup has been finally failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "monitoring user setup done"
  else
    loginfo "${FUNCNAME[0]}" "monitoring user setup skipped because of missing MARIADB_MONITORING_USER and/or MARIADB_MONITORING_PASSWORD env var"
  fi
}

function listdbandusers {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    checkdbk8sservicelogon "true"
    if [ $? -eq 0 ]; then
      break
    else
      loginfo "${FUNCNAME[0]}" "database not yet usable. Will wait ${WAIT_SECONDS}s before retry"
      sleep ${WAIT_SECONDS}
    fi
  done

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "list databases and users(${int} retries left)"
    mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=mariadb-galera-fe.database.svc.cluster.local --port=${MYSQL_PORT} --batch --execute="SHOW DATABASES; SELECT user,host FROM mysql.user;" --table
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "list databases and users has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "list databases and users has been finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "list databases and users done"
}

loginfo "null" "configuration job started"
setuprootuser
setupmonitoringuser
listdbandusers
loginfo "null" "configuration job finished"
