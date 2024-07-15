#!/usr/bin/env bash
set +e
set -u
set -o pipefail

REQUIRED_ENV_VARS=("DB_HOST" "DB_USER" "DB_PASSWORD" "DB_NAME")

function logjson {
  printf "{\"@timestamp\":\"%s\",\"ecs.version\":\"1.6.0\",\"log.logger\":\"%s\",\"log.origin.function\":\"%s\",\"log.level\":\"%s\",\"message\":\"%s\"}\n" "$(date +%Y-%m-%dT%H:%M:%S+%Z)" "$3" "$4" "$2" "$5" >>/dev/"$1"
}

function loginfo {
  logjson "stdout" "info" "$0" "$1" "$2"
}

function logdebug {
  logjson "stdout" "debug" "$0" "$1" "$2"
}

function logerror {
  logjson "stderr" "error" "$0" "$1" "$2"
}

function checkenv {
  local COUNTER=0
  for name in ${REQUIRED_ENV_VARS[@]}; do
    if [ -z ${!name+x} ]; then
      logerror "${FUNCNAME[0]}" "${name} environment variable not set"
      COUNTER=$((COUNTER + 1))
    fi
  done
  if [ "${COUNTER}" -gt "0" ]; then
    exit 1
  fi
}

function preparesysbench {
  loginfo "${FUNCNAME[0]}" "prepare ${SOFTWARE_NAME} tables in ${DB_NAME} database on ${DB_HOST}"
  /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --db-driver=mysql --mysql-dry-run=${SYSBENCH_MYSQL_DRY_RUN-off} \
    --mysql-host=${DB_HOST} --mysql-port=${DB_PORT-3306} \
    --mysql-user=${DB_USER} --mysql-password=${DB_PASSWORD} \
    --mysql-db=${DB_NAME} --table-size=${SYSBENCH_TABLE_SIZE-100} --tables=${SYSBENCH_TABLE_COUNT-10} --threads=${SYSBENCH_THREAD_COUNT-1} \
    /opt/${SOFTWARE_NAME}/share/${SOFTWARE_NAME}/${SYSBENCH_TEST_CASE-oltp_read_write}.lua prepare
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "${SOFTWARE_NAME} preparation failed"
    exit 1
  fi
}

function runsysbench {
  loginfo "${FUNCNAME[0]}" "run ${SOFTWARE_NAME} benchmark in ${DB_NAME} database on ${DB_HOST}"
  /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --db-driver=mysql --mysql-dry-run=${SYSBENCH_MYSQL_DRY_RUN-off} \
    --mysql-host=${DB_HOST} --mysql-port=${DB_PORT-3306} \
    --mysql-user=${DB_USER} --mysql-password=${DB_PASSWORD} \
    --mysql-db=${DB_NAME} --table-size=${SYSBENCH_TABLE_SIZE-100} --tables=${SYSBENCH_TABLE_COUNT-10} --threads=${SYSBENCH_THREAD_COUNT-1} \
    --report-interval=2 --time=${SYSBENCH_RUNTIME-30} \
    /opt/${SOFTWARE_NAME}/share/${SOFTWARE_NAME}/${SYSBENCH_TEST_CASE-oltp_read_write}.lua run
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "${SOFTWARE_NAME} run failed"
    exit 1
  fi
}

function cleanupsysbench {
  loginfo "${FUNCNAME[0]}" "cleanup ${DB_NAME} database on ${DB_HOST}"
  /opt/${SOFTWARE_NAME}/bin/${SOFTWARE_NAME} --db-driver=mysql --mysql-dry-run=${SYSBENCH_MYSQL_DRY_RUN-off} \
    --mysql-host=${DB_HOST} --mysql-port=${DB_PORT-3306} \
    --mysql-user=${DB_USER} --mysql-password=${DB_PASSWORD} \
    --mysql-db=${DB_NAME} --table-size=${SYSBENCH_TABLE_SIZE-100} --tables=${SYSBENCH_TABLE_COUNT-10} --threads=${SYSBENCH_THREAD_COUNT-1} \
    /opt/${SOFTWARE_NAME}/share/${SOFTWARE_NAME}/${SYSBENCH_TEST_CASE-oltp_read_write}.lua cleanup
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "${SOFTWARE_NAME} cleanup failed"
    exit 1
  fi
}

checkenv
preparesysbench
runsysbench
cleanupsysbench
