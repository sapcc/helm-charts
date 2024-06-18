#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

REQUIRED_ENV_VARS=("MARIADB_ROOT_USERNAME" "MARIADB_ROOT_PASSWORD")
declare -i MARIADBD_PID
MAX_RETRIES=10
WAIT_SECONDS=6

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
    readroleprivileges 'fullaccess' '/opt/mariadb/etc/sql/'
    readroleobject 'fullaccess' '/opt/mariadb/etc/sql/'
    readrolegrant 'fullaccess' '/opt/mariadb/etc/sql/'
    setuprole 'fullaccess' "${DB_ROLE_PRIVS}" "${DB_ROLE_OBJ}" "${DB_ROLE_GRANT}"
    # check if variables are set without triggering the "unbound variable" error
    # https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
    if [ ! -z ${MARIADB_MONITORING_USERNAME+x} ] && [ ! -z ${MARIADB_MONITORING_PASSWORD+x} ] ; then
      readroleprivileges 'monitor' '/opt/mariadb/etc/sql/'
      readroleobject 'monitor' '/opt/mariadb/etc/sql/'
      readrolegrant 'monitor' '/opt/mariadb/etc/sql/'
      setuprole 'monitor' "${DB_ROLE_PRIVS}" "${DB_ROLE_OBJ}" "${DB_ROLE_GRANT}"
    fi
    setupuser "${MARIADB_ROOT_USERNAME}" "${MARIADB_ROOT_PASSWORD}" 'fullaccess' 0 '%' 'ed25519' "WITH ADMIN OPTION"
    setupuser "${MARIADB_ROOT_USERNAME}" "${MARIADB_ROOT_PASSWORD}" 'fullaccess' 0 '::1' 'ed25519' "WITH ADMIN OPTION"
    # check if variables are set without triggering the "unbound variable" error
    # https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
    if [ ! -z ${MARIADB_MONITORING_USERNAME+x} ] && [ ! -z ${MARIADB_MONITORING_PASSWORD+x} ] ; then
      setupuser "${MARIADB_MONITORING_USERNAME}" "${MARIADB_MONITORING_PASSWORD}" 'monitor' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '%' 'mysql_native_password' " "
      setupuser "${MARIADB_MONITORING_USERNAME}" "${MARIADB_MONITORING_PASSWORD}" 'monitor' "${MARIADB_MONITORING_CONNECTION_LIMIT}" '::1' 'mysql_native_password' " "
      setupuser "${MARIADB_MONITORING_USERNAME}" "${MARIADB_MONITORING_PASSWORD}" 'monitor' "${MARIADB_MONITORING_CONNECTION_LIMIT}" 'localhost' 'mysql_native_password' " "
    fi
    setdefaultrole 'fullaccess' "${MARIADB_ROOT_USERNAME}" '%'
    setdefaultrole 'fullaccess' "${MARIADB_ROOT_USERNAME}" '::1'
    # check if variables are set without triggering the "unbound variable" error
    # https://www.gnu.org/software/bash/manual/bash.html#Shell-Parameter-Expansion
    if [ ! -z ${MARIADB_MONITORING_USERNAME+x} ] && [ ! -z ${MARIADB_MONITORING_PASSWORD+x} ] ; then
      setdefaultrole 'monitor' "${MARIADB_MONITORING_USERNAME}" '%'
      setdefaultrole 'monitor' "${MARIADB_MONITORING_USERNAME}" '::1'
      setdefaultrole 'monitor' "${MARIADB_MONITORING_USERNAME}" 'localhost'
      grantrole 'monitor' "${MARIADB_ROOT_USERNAME}" '%' 'WITH ADMIN OPTION'
      grantrole 'monitor' "${MARIADB_ROOT_USERNAME}" '::1' 'WITH ADMIN OPTION'
      grantrole 'monitor' "${MARIADB_ROOT_USERNAME}" 'localhost' 'WITH ADMIN OPTION'
    fi
    listdbandusers
    stopdb
  fi
  loginfo "${FUNCNAME[0]}" "init databases done"
}

function setuptimezoneinfo {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "setup timezone infos(${int} retries left)"
    mariadb-tzinfo-to-sql --defaults-file=${BASE}/etc/my.cnf --skip-write-binlog /usr/share/zoneinfo | mysql --protocol=socket --user=root --database=mysql --batch
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

    # if SOFTWARE_VERSION_CLEAN (left side) is bigger than MARIADB_OLDVERSION (right side) sort will return 1
    printf '%s\n%s' "${SOFTWARE_VERSION_CLEAN}" "${MARIADB_OLDVERSION[0]}" | sort --version-sort --check=silent
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
  mysql_upgrade --defaults-file=${BASE}/etc/my.cnf --protocol=socket --user=root --version-check
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
    mysql --protocol=socket --user=root --database=mysql --execute='STATUS;' | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
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

function wipedata {
  if [ -f "${BASE}/etc/wipedata.flag" ]; then
    loginfo "${FUNCNAME[0]}" "starting wipe of data and log folder content"
    rm -Rf ${DATADIR}/*
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "data folder wipe has been failed"
      exit 1
    fi
    rm -Rf ${LOGDIR}/*
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "log folder wipe has been failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "wipe of data and log folder content done"
  fi
}

wipedata
checkenv
templateconfig
initdb
checkupgradedb
startdb
