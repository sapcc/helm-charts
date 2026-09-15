#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh
REQUIRED_ENV_VARS=("MARIADB_MONITORING_USERNAME" "MARIADB_MONITORING_PASSWORD")

function checkenv {
  for name in ${REQUIRED_ENV_VARS[@]}; do
    if [ -z ${!name+x} ]; then
      logerror "${FUNCNAME[0]}" "${name} environment variable not set"
      exit 1
    fi
  done
}

function geteffectiveparametervalue {
  local -a paramlist=()

  for key in "${!exporterparams[@]}"
    do
      if [ -z "${exporterparams[$key]}" ]; then
        paramlist+="--$key "
      else
        paramlist+="--$key=${exporterparams[$key]} "
      fi
  done
  echo ${paramlist[@]}
}

function printexportersettings {
  local -a paramlist=($(geteffectiveparametervalue))
  for value in "${paramlist[@]}"
    do
      loginfo "${FUNCNAME[0]}" "$value"
  done
}

function startexporter {
  if [ -f "${BASE}/bin/entrypoint-mysqld_exporter.sh" ]; then
    source ${BASE}/bin/entrypoint-mysqld_exporter.sh
  else
    loginfo "${FUNCNAME[0]}" "starting mysqld_exporter process"
    exec ${BASE}/bin/mysqld_exporter $(geteffectiveparametervalue)
  fi
}

checkenv

DB_USERNAME=${MARIADB_MONITORING_USERNAME}
DB_PASS=${MARIADB_MONITORING_PASSWORD}
MYSQL_HOST=${DB_HOST-localhost}
MYSQL_PORT=${DB_PORT-3306}
WEB_LISTEN_ADDRESS="${WEB_LISTEN_HOST-}:${WEB_LISTEN_PORT-9104}"
export DATA_SOURCE_NAME=${COLLECT_DB_CONNECT_STRING-${DB_USERNAME}:${DB_PASS}@(${MYSQL_HOST}:${MYSQL_PORT})/}

declare -A exporterparams
#all parameters that should per default have values
exporterparams[log.level]+=${LOG_LEVEL-info}
exporterparams[log.format]+=${LOG_FORMAT-json}
exporterparams[timeout-offset]+=${TIMEOUT_OFFSET-0.25}
exporterparams[exporter.lock_wait_timeout]+=${EXPORTER_LOCK_WAIT_TIMEOUT-2}
exporterparams[web.listen-address]+="${WEB_LISTEN_ADDRESS-:9104}"
exporterparams[web.telemetry-path]+="${WEB_TELEMETRY_PATH-/metrics}"
exporterparams[collect.info_schema.tables.databases]+="${INFO_SCHEMA_DATABASES-*}"
exporterparams[collect.perf_schema.eventsstatements.digest_text_limit]+=${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS_DIGEST_TEXT_LIMIT-120}
exporterparams[collect.perf_schema.eventsstatements.limit]+=${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS_LIMIT-250}
exporterparams[collect.perf_schema.eventsstatements.timelimit]+=${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS_TIME_LIMIT-86400}
exporterparams[collect.perf_schema.file_instances.filter]+="${PERF_SCHEMA_FILE_INSTANCES_FILTER-.*}"
exporterparams[collect.perf_schema.file_instances.remove_prefix]+="${PERF_SCHEMA_FILE_INSTANCES_REMOVE_PREFIX-/opt/mariadb/data/}"
exporterparams[collect.perf_schema.memory_events.remove_prefix]+="${PERF_SCHEMA_MEMORY_EVENTS_REMOVE_RPEFIX-memory/}"
exporterparams[collect.info_schema.processlist.min_time]+=${COLLECT_INFO_SCHEMA_PROCESS_MIN_TIME-0}
exporterparams[collect.heartbeat.database]+="${COLLECT_HEARTBEAT_DATABASE-heartbeat}"
exporterparams[collect.heartbeat.table]+="${COLLECT_HEARTBEAT_TABLE-heartbeat}"
#all parameters that should per default be disabled
if ! [ -z ${WEB_CONFIG_FILE+x} ] && [ "${WEB_CONFIG_FILE}" == "enable" ]; then exporterparams[web.config.file]+="${WEB_CONFIG_FILE}"; fi
if ! [ -z ${EXPORTER_LOG_SLOW_FILTER+x} ] && [ "${EXPORTER_LOG_SLOW_FILTER}" == "enable" ]; then exporterparams[exporter.log_slow_filter]+=; fi
if ! [ -z ${TLS_INSECURE_SKIP_VERIFY+x} ] && [ "${TLS_INSECURE_SKIP_VERIFY}" == "enable" ]; then exporterparams[tls.insecure-skip-verify]+=; fi
if ! [ -z ${COLLECT_ENGINE_TOKUDB_STATUS+x} ] && [ "${COLLECT_ENGINE_TOKUDB_STATUS}" == "enable" ]; then exporterparams[collect.engine_tokudb_status]+=; else exporterparams[no-collect.engine_tokudb_status]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_INNODB_CMP+x} ] && [ "${COLLECT_INFO_SCHEMA_INNODB_CMP}" == "enable" ]; then exporterparams[collect.info_schema.innodb_cmp]+=; else exporterparams[no-collect.info_schema.innodb_cmp]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_INNODB_CMPMEM+x} ] && [ "${COLLECT_INFO_SCHEMA_INNODB_CMPMEM}" == "enable" ]; then exporterparams[collect.info_schema.innodb_cmpmem]+=; else exporterparams[no-collect.info_schema.innodb_cmpmem]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_REPLICA_HOST+x} ] && [ "${COLLECT_INFO_SCHEMA_REPLICA_HOST}" == "enable" ]; then exporterparams[collect.info_schema.replica_host]+=; else exporterparams[no-collect.info_schema.replica_host]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_REPLICATION_GROUP_MEMBERS+x} ] && [ "${COLLECT_PERF_SCHEMA_REPLICATION_GROUP_MEMBERS}" == "enable" ]; then exporterparams[collect.perf_schema.replication_group_members]+=; else exporterparams[no-collect.perf_schema.replication_group_members]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_REPLICATION_GROUP_MEMBER_STATS+x} ] && [ "${COLLECT_PERF_SCHEMA_REPLICATION_GROUP_MEMBER_STATS}" == "enable" ]; then exporterparams[collect.perf_schema.replication_group_member_stats]+=; else exporterparams[no-collect.perf_schema.replication_group_member_stats]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_REPLICATION_APPLIER_STATUS_BY_WORKER+x} ] && [ "${COLLECT_PERF_SCHEMA_REPLICATION_APPLIER_STATUS_BY_WORKER}" == "enable" ]; then exporterparams[collect.perf_schema.replication_applier_status_by_worker]+=; else exporterparams[no-collect.perf_schema.replication_applier_status_by_worker]+=; fi
if ! [ -z ${COLLECT_SLAVE_STATUS+x} ] && [ "${COLLECT_SLAVE_STATUS}" == "enable" ]; then exporterparams[collect.slave_status]+=; else exporterparams[no-collect.slave_status]+=; fi
if ! [ -z ${COLLECT_SLAVE_HOSTS+x} ] && [ "${COLLECT_SLAVE_HOSTS}" == "enable" ]; then exporterparams[collect.slave_hosts]+=; else exporterparams[no-collect.slave_hosts]+=; fi
if ! [ -z ${COLLECT_HEARTBEAT+x} ] && [ "${COLLECT_HEARTBEAT}" == "enable" ]; then exporterparams[collect.heartbeat]+=; else exporterparams[no-collect.heartbeat]+=; fi
if ! [ -z ${COLLECT_HEARTBEAT_UTC+x} ] && [ "${COLLECT_HEARTBEAT_UTC}" == "enable" ]; then exporterparams[collect.heartbeat.utc]+=; else exporterparams[no-collect.heartbeat.utc]+=; fi
if ! [ -z ${COLLECT_AUTO_INCREMENT_COLUMNS+x} ] && [ "${COLLECT_AUTO_INCREMENT_COLUMNS}" == "enable" ]; then exporterparams[collect.auto_increment.columns]+=; else exporterparams[no-collect.auto_increment.columns]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_INNODB_TABLESPACES+x} ] && [ "${COLLECT_INFO_SCHEMA_INNODB_TABLESPACES}" == "enable" ]; then exporterparams[collect.info_schema.innodb_tablespaces]+=; else exporterparams[no-collect.info_schema.innodb_tablespaces]+=; fi
#all parameters that should per default be enabled
if ! [ -z ${COLLECT_BIN_LOG_SIZE+x} ] && [ "${COLLECT_BIN_LOG_SIZE}" == "disable" ]; then exporterparams[no-collect.binlog_size]+=; else exporterparams[collect.binlog_size]+=; fi
if ! [ -z ${COLLECT_ENGINE_INNODB_STATUS+x} ] && [ "${COLLECT_ENGINE_INNODB_STATUS}" == "disable" ]; then exporterparams[no-collect.engine_innodb_status]+=; else exporterparams[collect.engine_innodb_status]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_TABLEIOWAITS+x} ] && [ "${COLLECT_PERF_SCHEMA_TABLEIOWAITS}" == "disable" ]; then exporterparams[no-collect.perf_schema.tableiowaits]+=; else exporterparams[collect.perf_schema.tableiowaits]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_TABLELOCKS+x} ] && [ "${COLLECT_PERF_SCHEMA_TABLELOCKS}" == "disable" ]; then exporterparams[no-collect.perf_schema.tablelocks]+=; else exporterparams[collect.perf_schema.tablelocks]+=; fi
if ! [ -z ${COLLECT_GLOBAL_STATUS+x} ] && [ "${COLLECT_GLOBAL_STATUS}" == "disable" ]; then exporterparams[no-collect.global_status]+=; else exporterparams[collect.global_status]+=; fi
if ! [ -z ${COLLECT_GLOBAL_VARIABLES+x} ] && [ "${COLLECT_GLOBAL_VARIABLES}" == "disable" ]; then exporterparams[no-collect.global_variables]+=; else exporterparams[collect.global_variables]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_INNODB_METRICS+x} ] && [ "${COLLECT_INFO_SCHEMA_INNODB_METRICS}" == "disable" ]; then exporterparams[no-collect.info_schema.innodb_metrics]+=; else exporterparams[collect.info_schema.innodb_metrics]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_PROCESS_LIST+x} ] && [ "${COLLECT_INFO_SCHEMA_PROCESS_LIST}" == "disable" ]; then exporterparams[no-collect.info_schema.processlist]+=; else exporterparams[collect.info_schema.processlist]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_QUERY_RESPONSE_TIME+x} ] && [ "${COLLECT_INFO_SCHEMA_QUERY_RESPONSE_TIME}" == "disable" ]; then exporterparams[no-collect.info_schema.processlist]+=; else exporterparams[collect.info_schema.query_response_time]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_SCHEMASTATS+x} ] && [ "${COLLECT_INFO_SCHEMA_SCHEMASTATS}" == "disable" ]; then exporterparams[no-collect.info_schema.schemastats]+=; else exporterparams[collect.info_schema.schemastats]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_USERSTATS+x} ] && [ "${COLLECT_INFO_SCHEMA_USERSTATS}" == "disable" ]; then exporterparams[no-collect.info_schema.userstats]+=; else exporterparams[collect.info_schema.userstats]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_CLIENTSTATS+x} ] && [ "${COLLECT_INFO_SCHEMA_CLIENTSTATS}" == "disable" ]; then exporterparams[no-collect.info_schema.clientstats]+=; else exporterparams[collect.info_schema.clientstats]+=; fi
if ! [ -z ${COLLECT_MYSQL_USER+x} ] && [ "${COLLECT_MYSQL_USER}" == "disable" ]; then exporterparams[no-collect.mysql.user]+=; else exporterparams[collect.mysql.user]+=; fi
if ! [ -z ${COLLECT_MYSQL_USER_PRIVILEGES+x} ] && [ "${COLLECT_MYSQL_USER_PRIVILEGES}" == "disable" ]; then exporterparams[no-collect.mysql.user.privileges]+=; else exporterparams[collect.mysql.user.privileges]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_INDEXIOWAITS+x} ] && [ "${COLLECT_PERF_SCHEMA_INDEXIOWAITS}" == "disable" ]; then exporterparams[no-collect.perf_schema.indexiowaits]+=; else exporterparams[collect.perf_schema.indexiowaits]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_TABLES+x} ] && [ "${COLLECT_INFO_SCHEMA_TABLES}" == "disable" ]; then exporterparams[no-collect.info_schema.tables]+=; else exporterparams[collect.info_schema.tables]+=; fi
if ! [ -z ${COLLECT_INFO_SCHEMA_TABLESTATS+x} ] && [ "${COLLECT_INFO_SCHEMA_TABLESTATS}" == "disable" ]; then exporterparams[no-collect.info_schema.tablestats]+=; else exporterparams[collect.info_schema.tablestats]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_EVENTSWAITS+x} ] && [ "${COLLECT_PERF_SCHEMA_EVENTSWAITS}" == "disable" ]; then exporterparams[no-collect.perf_schema.eventswaits]+=; else exporterparams[collect.perf_schema.eventswaits]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_FILE_EVENTS+x} ] && [ "${COLLECT_PERF_SCHEMA_FILE_EVENTS}" == "disable" ]; then exporterparams[no-collect.perf_schema.file_events]+=; else exporterparams[collect.perf_schema.file_events]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS_SUM+x} ] && [ "${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS_SUM}" == "disable" ]; then exporterparams[no-collect.perf_schema.eventsstatementssum]+=; else exporterparams[collect.perf_schema.eventsstatementssum]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS+x} ] && [ "${COLLECT_PERF_SCHEMA_EVENTSSTATEMENTS}" == "disable" ]; then exporterparams[no-collect.perf_schema.eventsstatements]+=; else exporterparams[collect.perf_schema.eventsstatements]+=; fi
if ! [ -z ${COLLECT_PERF_SCHEMA_MEMORY_EVENTS+x} ] && [ "${COLLECT_PERF_SCHEMA_MEMORY_EVENTS}" == "disable" ]; then exporterparams[no-collect.perf_schema.memory_events]+=; else exporterparams[collect.perf_schema.memory_events]+=; fi

printexportersettings
startexporter
