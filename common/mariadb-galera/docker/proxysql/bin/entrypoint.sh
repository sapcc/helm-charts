#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

REQUIRED_ENV_VARS=("PROXYSQL_ADMIN_USERNAME" "PROXYSQL_ADMIN_PASSWORD" "MARIADB_MONITORING_USERNAME" "MARIADB_MONITORING_PASSWORD" "PROXYSQL_STATS_USERNAME" "PROXYSQL_STATS_PASSWORD")
MAX_RETRIES=10
WAIT_SECONDS=6
export PROXYSQL_ADMIN_PORT="${PROXYSQL_ADMIN_PORT:-6032}"
export PROXYSQL_MYSQL_PORT="${PROXYSQL_MYSQL_PORT:-6033}"
export PROXYSQL_WEB_ENABLED="${PROXYSQL_WEB_ENABLED:-false}"
export PROXYSQL_WEB_PORT="${PROXYSQL_WEB_PORT:-6080}"
export PROXYSQL_WEB_VERBOSITY="${PROXYSQL_WEB_VERBOSITY:-0}"
export PROXYSQL_RESTAPI_ENABLED="${PROXYSQL_RESTAPI_ENABLED:-false}"
export PROXYSQL_RESTAPI_PORT="${PROXYSQL_RESTAPI_PORT:-6070}"

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
      export ${name}=$(cat /proc/sys/kernel/random/uuid | head -c 32)
    fi
  done
}

function templateconfig {
  local int
  local templatefile
  local templatefilewithoutext

  loginfo "${FUNCNAME[0]}" "template ProxySQL configurations"
  for templatepath in /opt/${SOFTWARE_NAME}/etc/tpl/*.tpl;
    do
    templatefile=${templatepath##*/}
    templatefilewithoutext=${templatefile%%.*}
    envsubst < ${templatepath} > /opt/${SOFTWARE_NAME}/etc/${templatefilewithoutext}.cfg
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "${templatepath} rendering has been failed"
      exit 1
    fi
  done
  loginfo "${FUNCNAME[0]}" "template ProxySQL configurations done"
}

function startproxy {
  if [ -f "${BASE}/bin/entrypoint-cluster.sh" ]; then
    source ${BASE}/bin/entrypoint-cluster.sh
  else
    loginfo "${FUNCNAME[0]}" "starting proxysql process"
    exec proxysql --config ${BASE}/etc/proxysql.cfg --exit-on-error --idle-threads --reload --no-version-check --foreground
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "proxysql startup failed"
      exit 1
    fi
  fi
}

checkenv
templateconfig
startproxy
