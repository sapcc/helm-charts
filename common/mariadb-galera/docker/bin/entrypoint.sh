
#!/usr/bin/env bash
set +e
set -u
set -o pipefail
set +x

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
REQUIRED_ENV_VARS=("MARIADB_ROOT_PASSWORD")
declare -i MARIADBD_PID
MAX_RETRIES=10
WAIT_SECONDS=6

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y.%m.%d-%H:%M:%S-%Z)" "$2" "$3" >>/dev/"$1"
}

function loginfo {
  logjson  "stdout" "info" "$1"
}

function logerror {
  logjson  "stderr" "error" "$1"
}

function checkenv {
  for name in ${REQUIRED_ENV_VARS[@]}; do
    if [ -z ${!name+x} ]; then
      logerror "${name} environment variable not set"
      exit 1
    fi
  done
}

function initdb {
  loginfo "init databases if required"
  # check if the data folder already contains database structures
  if [ -d "${BASE}/data/mysql" ]; then
    loginfo "Database structures already exist"
    return
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
      logerror "Database initialization has been failed"
      exit 1
    fi
    startmaintenancedb
    setuptimezoneinfo
    setupusers
    listdbandusers
    stopdb
  fi
  loginfo "init databases done"
}

function setupusers {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "setup root user permissions(${int} retries left)"
    cat ${BASE}/etc/sql/root_permissions.sql.tpl | envsubst | mysql --defaults-file=${BASE}/etc/my.cnf -u root -h localhost --batch
    if [ $? -ne 0 ]; then
      logerror "root user setup has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "root user setup has been finally failed"
    exit 1
  fi
  loginfo "root user setup done"
}

function listdbandusers {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "list databases and users(${int} retries left)"
    mysql --defaults-file=${BASE}/etc/my.cnf -u root -h localhost --batch --execute="SHOW DATABASES; SELECT user,host FROM mysql.user;" --table
    if [ $? -ne 0 ]; then
      logerror "list databases and users has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "list databases and users has been finally failed"
    exit 1
  fi
  loginfo "list databases and users done"
}

function setuptimezoneinfo {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "setup timezone infos(${int} retries left)"
    mariadb-tzinfo-to-sql --defaults-file=${BASE}/etc/my.cnf --skip-write-binlog /usr/share/zoneinfo | mysql --defaults-file=${BASE}/etc/my.cnf -u root -h localhost --database=mysql --batch
    if [ $? -ne 0 ]; then
      logerror "timezone info setup has been failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "timezone info setup has been finally failed"
    exit 1
  fi
  loginfo "timezone info setup done"
}

function upgradedbifrequired {
  if [ ! -f ${DATADIR}/mysql_upgrade_info ]; then
    loginfo "MariaDB upgrade information missing, assuming required"
    startmaintenancedb
    upgradedb
    stopdb
  else
    IFS=".-" MARIADB_OLDVERSION=($(echo$(cat ${DATADIR}/mysql_upgrade_info)))
    IFS="${oldIFS}"

    # if SOFTWARE_VERSION (left side) is bigger than MARIADB_OLDVERSION (right side) sort will return 1
    printf '%s\n%s' "${SOFTWARE_VERSION}" "${MARIADB_OLDVERSION}" | sort --version-sort --check=silent
    if [ $? -ne 0 ]; then
      loginfo "MariaDB version higher than last upgrade info"
      startmaintenancedb
      upgradedb
      stopdb
    else
      loginfo "MariaDB version same as last upgrade info, no upgrade required"
    fi
  fi
}

function upgradedb {
  loginfo "start database upgrade"
  mysql_upgrade --defaults-file=${BASE}/etc/my.cnf -u root -h localhost --version-check
  if [ $? -ne 0 ]; then
    logerror "database upgrade has been failed"
    exit 1
  fi
  loginfo "database upgrade done"
}

function startdb {
  if [ -f "${BASE}/bin/entrypoint-galera.sh" ]; then
    source ${BASE}/bin/entrypoint-galera.sh
  else
    loginfo "starting mariadbd process"
    mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error
    if [ $? -ne 0 ]; then
      logerror "mariadbd startup failed"
      exit 1
    fi
  fi
}

function startmaintenancedb {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "starting mariadbd process for maintenance(${int} retries left)"
    mariadbd --defaults-file=${BASE}/etc/my.cnf --basedir=/usr --skip-log-error \
    --skip-networking=1 \
    --wsrep_on=OFF \
    --expire-logs-days=0 \
    --loose-innodb_buffer_pool_load_at_startup=0 &
    if [ $? -ne 0 ]; then
      logerror "mariadbd maintenance startup failed"
      sleep ${WAIT_SECONDS}
    fi
    MARIADBD_PID=$!
    ps --no-headers --pid ${MARIADBD_PID} | grep --silent mariadbd
    if [ $? -eq 0 ]; then
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "mariadbd maintenance startup finally failed"
    exit 1
  fi

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "check if mariadbd is usable for maintenance(${int} retries left)"
    mysql --defaults-file=${BASE}/etc/my.cnf -u root -h localhost --database=mysql --execute='STATUS;' | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
    if [ $? -ne 0 ]; then
      logerror "mariadbd check failed"
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "mariadbd maintenance startup finally failed"
    exit 1
  fi

  loginfo "mariadbd maintenance startup done"
}

function stopdb {
  local int
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "stop mariadbd process with pid ${MARIADBD_PID}(${int} retries left)"
    kill -s TERM ${MARIADBD_PID}
    if [ $? -ne 0 ]; then
      logerror "mariadbd stop has been failed"
      sleep ${WAIT_SECONDS}
    fi
    ps --no-headers --pid ${MARIADBD_PID} | grep --silent mariadbd
    if [ $? -eq 0 ]; then
      break
    fi
  done
  if [ ${int} = 0 ]; then
    logerror "mariadbd stop has been finally failed"
    exit 1
  fi
  loginfo "mariadbd stop done"
}

checkenv
initdb
upgradedbifrequired
startdb
