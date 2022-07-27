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

# setup username password rolename rolename connectionlimit
# setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}"
function setupuser {
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

  if [ -f "${BASE}/etc/sql/user.sql.tpl" ] && [ -n "${1}" ] && [ -n "${2}" ]; then
    local int
    export DB_USER=${1}
    export DB_PASS=${2}
    export DB_ROLE=${3}
    export CONN_LIMIT=${4}
    declare -a DB_HOST_LIST=('%' '127.0.0.1' '::1')

    loginfo "${FUNCNAME[0]}" "setup user privileges"
    while read -r line
      do
      IFS=";" read -a sqlarray <<< ${line}
      IFS="${oldIFS}"
      export SQL_CODE=${sqlarray[0]}
      if ! [ -z ${sqlarray[1]+x} ]; then
        export WITH_OPTION=${sqlarray[1]}
      else
        export WITH_OPTION=''
      fi
      for (( int=${MAX_RETRIES}; int >=1; int-=1));
        do
        cat ${BASE}/etc/sql/role.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host={{ $.Values.namePrefix | default "mariadb-g" }}-frontend.database.svc.cluster.local --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "'${DB_ROLE}' role setup '${SQL_CODE}' has been failed(${int} retries left)"
          sleep ${WAIT_SECONDS}
        else
          loginfo "${FUNCNAME[0]}" "'${DB_ROLE}' role setup '${SQL_CODE}' done"
          break
        fi
      done
    done < <(grep -v "^#" ${BASE}/etc/sql/${DB_ROLE}.role)

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "user setup has been finally failed"
      exit 1
    fi

    for host in ${DB_HOST_LIST[@]}
      do
      export DB_HOST=${host}
      for (( int=${MAX_RETRIES}; int >=1; int-=1));
        do
        cat ${BASE}/etc/sql/user.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host={{ $.Values.namePrefix | default "mariadb-g" }}-frontend.database.svc.cluster.local --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "'${DB_USER}@${DB_HOST}' user setup has been failed(${int} retries left)"
          sleep ${WAIT_SECONDS}
        else
          loginfo "${FUNCNAME[0]}" "'${DB_USER}@${DB_HOST}' user setup done"
          break
        fi
      done
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "user setup has been finally failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "user setup done"
  else
    loginfo "${FUNCNAME[0]}" "user setup skipped because of missing MARIADB_XYZ_USER and/or MARIADB_XYZ_PASSWORD env var"
  fi
  export -n DB_USER
  export -n DB_PASS
  export -n DB_HOST
  export -n CONN_LIMIT
  export -n SQL_CODE
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
    mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host={{ $.Values.namePrefix | default "mariadb-g" }}-frontend.database.svc.cluster.local --port=${MYSQL_PORT} --batch --execute="SHOW DATABASES; SELECT user,host FROM mysql.user; SELECT * FROM information_schema.APPLICABLE_ROLES;" --table
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
setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}"
listdbandusers
loginfo "null" "configuration job finished"
