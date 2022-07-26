
#!/usr/bin/env bash
set +e
set -u
set -o pipefail

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
REQUIRED_ENV_VARS=("MARIADB_ROOT_PASSWORD")
declare -i MARIADBD_PID
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

function checkenv {
  for name in ${REQUIRED_ENV_VARS[@]}; do
    if [ -z ${!name+x} ]; then
      logerror "${FUNCNAME[0]}" "${name} environment variable not set"
      exit 1
    fi
  done
}

function initdb {
  loginfo "${FUNCNAME[0]}" "init databases if required"
  # check if the data folder already contains database structures
  if [ -d "${BASE}/data/mysql" ]; then
    loginfo "${FUNCNAME[0]}" "Database structures already exist"
  else
    /usr/bin/mariadb-install-db --defaults-file=${BASE}/etc/my.cnf --basedir=/usr \
    --auth-root-authentication-method=normal \
    --skip-test-db \
    --default-time-zone=SYSTEM \
    --enforce-storage-engine= \
    --skip-log-bin \
    --expire-logs-days=0 \
    --loose-innodb_buffer_pool_load_at_startup=0 \
    --loose-innodb_buffer_pool_dump_at_shutdown=0
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "Database initialization has been failed"
      exit 1
    fi
    startmaintenancedb
    setuptimezoneinfo
    setupuser "${MARIADB_ROOT_USER}" "${MARIADB_ROOT_PASSWORD}" 'fullaccess' 0
    setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}"
    listdbandusers
    stopdb
  fi
  loginfo "${FUNCNAME[0]}" "init databases done"
}

# setup username password rolename rolename connectionlimit
# setupuser "${MARIADB_MONITORING_USER}" "${MARIADB_MONITORING_PASSWORD}" 'mysql_exporter' "${MARIADB_MONITORING_CONNECTION_LIMIT}"
function setupuser {
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
        cat ${BASE}/etc/sql/role.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --batch
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
        cat ${BASE}/etc/sql/user.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --batch
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
    loginfo "${FUNCNAME[0]}" "list databases and users(${int} retries left)"
    mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --batch --execute="SHOW DATABASES; SELECT user,host FROM mysql.user; SELECT * FROM information_schema.APPLICABLE_ROLES;" --table
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

function setuptimezoneinfo {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "setup timezone infos(${int} retries left)"
    mariadb-tzinfo-to-sql --defaults-file=${BASE}/etc/my.cnf --skip-write-binlog /usr/share/zoneinfo | mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --database=mysql --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "timezone info setup has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "timezone info setup has been finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "timezone info setup done"
}

function checkupgradedb {
  if [ ! -f ${DATADIR}/mysql_upgrade_info ]; then
    loginfo "${FUNCNAME[0]}" "MariaDB upgrade information missing, assuming required"
    startmaintenancedb
    upgradedb
    stopdb
  else
    IFS="- " read -ra MARIADB_OLDVERSION < /opt/mariadb/data/mysql_upgrade_info
    IFS="${oldIFS}"

    # if SOFTWARE_VERSION (left side) is bigger than MARIADB_OLDVERSION (right side) sort will return 1
    printf '%s\n%s' "${SOFTWARE_VERSION}" "${MARIADB_OLDVERSION}" | sort --version-sort --check=silent
    if [ $? -ne 0 ]; then
      loginfo "${FUNCNAME[0]}" "MariaDB version higher than last upgrade info"
      startmaintenancedb
      upgradedb
      stopdb
    else
      loginfo "${FUNCNAME[0]}" "MariaDB version same as last upgrade info, no upgrade required"
    fi
  fi
}

function upgradedb {
  loginfo "${FUNCNAME[0]}" "start database upgrade"
  mysql_upgrade --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --version-check
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "database upgrade has been failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "database upgrade done"
}

function startdb {
  if [ -f "${BASE}/bin/entrypoint-galera.sh" ]; then
    source ${BASE}/bin/entrypoint-galera.sh
  else
    loginfo "${FUNCNAME[0]}" "starting mariadbd process"
    exec mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadbd startup failed"
      exit 1
    fi
  fi
}

function startmaintenancedb {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "starting mariadbd process for maintenance(${int} retries left)"
    mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error \
    --skip-networking=1 \
    --wsrep_on=OFF \
    --expire-logs-days=0 \
    --loose-innodb_buffer_pool_load_at_startup=0 &
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadbd maintenance startup failed"
      sleep ${WAIT_SECONDS}
    fi
    MARIADBD_PID=$!
    ps --no-headers --pid ${MARIADBD_PID} | grep --silent mariadbd
    if [ $? -eq 0 ]; then
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "mariadbd maintenance startup finally failed"
    exit 1
  fi

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "check if mariadbd is usable for maintenance(${int} retries left)"
    mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --database=mysql --execute='STATUS;' | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadbd check failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "mariadbd maintenance startup finally failed"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "mariadbd maintenance startup done"
}

function stopdb {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "stop mariadbd process with pid ${MARIADBD_PID}(${int} retries left)"
    kill ${MARIADBD_PID}
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadbd stop has been failed"
      sleep ${WAIT_SECONDS}
    fi
    wait ${MARIADBD_PID}
    if [ $? -eq 0 ]; then
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "mariadbd stop has been finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "mariadbd stop done"
}

checkenv
initdb
checkupgradedb
startdb
