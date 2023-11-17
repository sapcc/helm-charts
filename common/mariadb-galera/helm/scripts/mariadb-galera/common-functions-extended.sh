MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}
if [ "$0" != "/opt/mariadb/bin/entrypoint-backup.sh" ]; then
  MYSQL_SVC_CONNECT="mysql --protocol=tcp --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --host={{ printf "%s-%s-direct.%s" (include "commonPrefix" $) "mariadb" $.Release.Namespace }} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch"
fi
declare -a NODENAME=()

#entrypoint-galera
# setconfigmap "scope[seqno|running|primary]" "value[sequence number|true|false]" "output[Update|Reset]"
function setconfigmap {
  local int
  local SCOPE=$1
  local VALUE=$2
  local OUTPUT=$3
  declare -l OUTPUT_LOWERCASE=${OUTPUT}
  if [ ${OUTPUT} == "Reset" ]; then
    local CONTENT="${VALUE}\ntimestamp:\n"
  else
    local CONTENT="${VALUE}\ntimestamp:$(date +%s)\n"
  fi
  local CONFIGMAP_NAME={{ include "commonPrefix" $ }}-galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "${OUTPUT} configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time ${WAIT_SECONDS} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${POD_NAME}.${SCOPE}\":\"${POD_NAME}:${CONTENT}\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/{{ $.Release.Namespace }}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.scripts.logLevel "debug" }} logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' ${OUTPUT_LOWERCASE} has been failed because of ${HTTP_OUTPUT}" {{ else }} logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' ${OUTPUT_LOWERCASE} has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' ${OUTPUT_LOWERCASE} has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' ${OUTPUT_LOWERCASE} done with '${HTTP_OUTPUT}'" {{ else }} loginfo "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' ${OUTPUT_LOWERCASE} done with http status code '${HTTP_STATUS}'" {{ end }}
}

function fetchcurrentseqno {
  local int
  local SEQNOARRAY

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    IFS=$'\t' SEQNOARRAY=($(mysql --protocol=socket --user=root --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    exit 1
  fi
  IFS="${oldIFS}"
  echo ${SEQNOARRAY[1]}
}

function checkdblogon {
  mysql --protocol=socket --user=root --database=mysql --wait --connect-timeout=${WAIT_SECONDS} --reconnect --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API usable'
  else
    echo 'MariaDB MySQL API not usable'
    exit 1
  fi
}

function checkdbk8sservicelogon {
  local ONLY_RETURN_STATUS=${1-false}

  ${MYSQL_SVC_CONNECT} --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    if [ "${ONLY_RETURN_STATUS}" == "true" ]; then
      return 0
    else
      echo 'MariaDB MySQL API Kubernetes service usable'
    fi
  else
    if [ "${ONLY_RETURN_STATUS}" == "true" ]; then
      return 1
    else
      echo 'MariaDB MySQL API Kubernetes service not usable'
      exit 1
    fi
  fi
}

function waitfordatabase {
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
}

# setupdatabase dbname comment collation charset enabled createOrReplace deleteIfDisabled
# setupdatabase "sb_oltp_ro" "for the sysbench oltp readonly benchmark" "utf8_general_ci" "utf8" true true true
function setupdatabase {
  if [ -n "${7}" ]; then
    local int
    export DB_NAME=${1}
    export DB_COMMENT=${2}
    export DB_COLLATION=${3}
    export DB_CHARSET=${4}
    export DB_ENABLED=${5}
    export DB_REPLACE=${6}
    export DB_DELETE=${7}

    if [ "${DB_REPLACE}" == "true" ]; then
      export DB_CREATE="CREATE OR REPLACE DATABASE"
    else
      export DB_CREATE="CREATE DATABASE IF NOT EXISTS"
    fi

    loginfo "${FUNCNAME[0]}" "setup '${DB_NAME}' database"
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      if [ "${DB_ENABLED}" == "true" ]; then
        if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
          ${MYSQL_SVC_CONNECT} --execute="${DB_CREATE} ${DB_NAME} CHARACTER SET = ${DB_CHARSET} COLLATE = ${DB_COLLATION} COMMENT '${DB_COMMENT}';"
        else
          mysql --protocol=socket --user=root --batch --execute="${DB_CREATE} ${DB_NAME} CHARACTER SET = ${DB_CHARSET} COLLATE = ${DB_COLLATION} COMMENT '${DB_COMMENT}';"
        fi
        if [ $? -ne 0 ]; then
          logerror "${FUNCNAME[0]}" "'${DB_NAME}' database creation has been failed(${int} retries left)"
          sleep ${WAIT_SECONDS}
        else
          loginfo "${FUNCNAME[0]}" "'${DB_NAME}' database creation done"
          break
        fi
      else
        if [ "${DB_DELETE}" == "true" ]; then
          if [ "$0" == "/opt/mariadb/bin/entrypoint-job-config.sh" ]; then
            ${MYSQL_SVC_CONNECT} --execute="DROP DATABASE IF EXISTS ${DB_NAME};"
          else
            mysql --protocol=socket --user=root --batch --execute="DROP DATABASE IF EXISTS ${DB_NAME};"
          fi
          if [ $? -ne 0 ]; then
            logerror "${FUNCNAME[0]}" "'${DB_NAME}' database delete has been failed(${int} retries left)"
            sleep ${WAIT_SECONDS}
          else
            loginfo "${FUNCNAME[0]}" "'${DB_NAME}' database deletion done"
            break
          fi
        else
          loginfo "${FUNCNAME[0]}" "'${DB_NAME}' database deletion not allowed because deleteIfDisabled option is not enabled"
          break
        fi
      fi
    done

    if [ ${int} -eq 0 ]; then
      logerror "${FUNCNAME[0]}" "database setup has been finally failed"
      exit 1
    fi
    export -n DB_NAME
    export -n DB_COMMENT
    export -n DB_COLLATION
    export -n DB_CHARSET
    export -n DB_ENABLED
    export -n DB_REPLACE
    export -n DB_DELETE
    export -n DB_CREATE
  else
    loginfo "${FUNCNAME[0]}" "database setup skipped because of missing parameters"
  fi
}

function selectbootstrapnode {
  local int
  local SEQNO=$(fetchseqnofromgrastate)
  local SEQNO_FILES="${BASE}/etc/galerastatus/{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-*.seqno"
  local SEQNO_OLDEST_TIMESTAMP
  local SEQNO_OLDEST_TIMESTAMP_WITH_BUFFER
  local CURRENT_EPOCH

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "Find Galera node with highest sequence number (${int} retries left)"
    SEQNO_FILE_COUNT=$(grep -c '{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-*' ${SEQNO_FILES} | grep -c -e ${BASE}/etc/galerastatus/{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-.*.seqno:1)
    if [ ${SEQNO_FILE_COUNT} -ge {{ ($.Values.replicas.database|int) }} ]; then
      IFS=":" SEQNO_OLDEST_TIMESTAMP=($(grep --no-filename --perl-regex --regexp='^timestamp:\d+$' ${SEQNO_FILES} | sort --key=2 --numeric-sort --field-separator=: | head --lines=1))
      IFS="${oldIFS}"
      if ! [ -z ${SEQNO_OLDEST_TIMESTAMP[1]+x} ]; then
        SEQNO_OLDEST_TIMESTAMP_WITH_BUFFER=$(( ${SEQNO_OLDEST_TIMESTAMP[1]} + ({{ $.Values.readinessProbe.timeoutSeconds.database | int }} * {{ $.Values.scripts.maxAllowedTimeDifferenceFactor | default 3 | int }}) ))
        CURRENT_EPOCH=$(date +%s)
        {{- if $.Values.scripts.useTimeDifferenceForSeqnoCheck }}
        if [ ${CURRENT_EPOCH} -le ${SEQNO_OLDEST_TIMESTAMP_WITH_BUFFER} ]; then
        {{- else }}
        # time difference check disabled
        {{- end }}
          IFS=": " NODENAME=($(grep --no-filename '{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-*' ${SEQNO_FILES} | sort --key=2 --reverse --numeric-sort --field-separator=: | head -1))
          IFS="${oldIFS}"
          if [[ "${NODENAME[0]}" =~ ^{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-.* ]]; then
            loginfo "${FUNCNAME[0]}" "Galera nodename '${NODENAME[0]}' with the sequence number '${NODENAME[1]}' selected"
            break
          else
            logerror "${FUNCNAME[0]}" "nodename '${NODENAME[0]}' not valid"
            exit 1
          fi
        {{- if $.Values.scripts.useTimeDifferenceForSeqnoCheck }}
        else
          logerror "${FUNCNAME[0]}" "seqno timestamp of at least one node is too old: '$(date --date=@${SEQNO_OLDEST_TIMESTAMP_WITH_BUFFER} +%Y.%m.%d-%H:%M:%S-%Z)'/'$(date --date=@${CURRENT_EPOCH} +%Y.%m.%d-%H:%M:%S-%Z)' will wait $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))s"
          sleep  $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))
        fi
        {{- end }}
      else
        loginfo "${FUNCNAME[0]}" "Sequence numbers not yet found in configmap. Retry after $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))s"
        sleep  $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))
      fi
    else
      loginfo "${FUNCNAME[0]}" "${SEQNO_FILE_COUNT} of {{ ($.Values.replicas.database|int) }} sequence numbers found. Will wait $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))s"
      sleep  $(( ${WAIT_SECONDS} * (${MAX_RETRIES} - ${int} + 1) ))
    fi
    setconfigmap "seqno" "${SEQNO}" "Update"
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "Sequence number search finally incomplete(${SEQNO_FILE_COUNT}/{{ ($.Values.replicas.database|int)}})"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "Sequence number search done"
}

function setupasyncreplication {
  local int
  local primaryhost={{ required "mariadb.asyncReplication.primaryHost setting required for async replication" $.Values.mariadb.asyncReplication.primaryHost | quote }}
  local gtidbinlogposition
  local gtidlist

  loginfo "${FUNCNAME[0]}" "setup async replication from '${primaryhost}'"
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    # use only the wsrep_gtid_domain_id values like '10815-10-2809143'
    IFS=$'\n' gtidlist=($(mysql --protocol=tcp --host=${primaryhost} --user=${REPLICA_USERNAME} --password=${REPLICA_PASSWORD} --execute="select @@gtid_binlog_pos;" --batch --skip-column-names | grep --only-matching --perl-regexp --regexp='(?<=)\d{1}0815-\d{2}-\d+'))
    IFS="${oldIFS}"
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "'gtid_binlog_pos query failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      # join array values to something like '10815-10-2809143,20815-20-442922'
      gtidbinlogposition=$(IFS=','; echo "${gtidlist[*]}")
      IFS="${oldIFS}"
      {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "current gtid_binlog_pos '${gtidbinlogposition}' found on '${primaryhost}'" {{ end }}
      break
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "async replication setup has been finally failed"
    exit 1
  fi

  {{- if $.Values.mariadb.asyncReplication.resetConfig }}
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    mysql --protocol=tcp --host={{ include "nodeNamePrefix" (dict "global" $ "component" "database") }}-0 --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="SET GLOBAL gtid_slave_pos=\"${gtidbinlogposition}\";" --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "'gtid_slave_pos update failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "gtid_slave_pos '${gtidbinlogposition}' successfully updated" {{ end }}
      break
    fi
  done
  {{- end }}

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "async replication setup has been finally failed"
    exit 1
  fi

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    mysql --protocol=tcp --host={{ include "nodeNamePrefix" (dict "global" $ "component" "database") }}-0 --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="CHANGE MASTER TO MASTER_HOST=\"${primaryhost}\", MASTER_PORT=${MYSQL_PORT}, MASTER_USERNAME=\"${REPLICA_USERNAME}\", MASTER_PASSWORD=\"${REPLICA_PASSWORD}\", MASTER_USE_GTID=slave_pos, DO_DOMAIN_IDS=({{ include "domainIdList" (dict "global" $) }}), IGNORE_SERVER_IDS=({{ include "serverIdList" (dict "global" $) }});" --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "'change master config failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "master config successfully updated" {{ end }}
      break
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "async replication setup has been finally failed"
    exit 1
  fi
}

function stopasyncreplication {
  local int

  loginfo "${FUNCNAME[0]}" "stop async replication"
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    mysql --protocol=tcp --host={{ include "nodeNamePrefix" (dict "global" $ "component" "database") }}-0 --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute={{- if $.Values.mariadb.asyncReplication.resetConfig }}"STOP ALL SLAVES;RESET SLAVE ALL;"{{- else }}"STOP ALL SLAVES;"{{- end }} --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "'replica stop failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      loginfo "${FUNCNAME[0]}" "replica stop successful"
      break
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "async replication stop has been finally failed"
    exit 1
  fi
}

function startasyncreplication {
  local int

  loginfo "${FUNCNAME[0]}" "start async replication"
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    mysql --protocol=tcp --host={{ include "nodeNamePrefix" (dict "global" $ "component" "database") }}-0 --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="START ALL SLAVES;" --batch
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "'replica start failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      loginfo "${FUNCNAME[0]}" "replica start successful"
      break
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "async replication start has been finally failed"
    exit 1
  fi
}

function checkasyncreplication {
  local int
  local SLAVEIO_STATUS
  local SLAVEIO_ERRNR
  local SLAVEIO_ERRTXT
  local SLAVESQL_STATUS
  local SLAVESQL_ERRNR
  local SLAVESQL_ERRTXT

  loginfo "${FUNCNAME[0]}" "check async replication status"
  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    MYSQL_RESPONSE=$(mysql --protocol=tcp --host={{ include "nodeNamePrefix" (dict "global" $ "component" "database") }}-0 --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="SHOW ALL SLAVES STATUS\G;" --batch)
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "replica status check failed(${int} retries left)"
      sleep ${WAIT_SECONDS}
    else
      SLAVEIO_STATUS=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Slave_IO_Running: )(No|Yes|Connecting)')
      if [ "${SLAVEIO_STATUS}" != "Connecting" ]; then
        {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "replica status query successful" {{ end }}
        break
      else
        logerror "${FUNCNAME[0]}" "replica still trying to connect to the primary(${int} retries left)"
        sleep ${WAIT_SECONDS}
      fi
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "replica status check has been finally failed"
    exit 1
  fi

  IFS=""
  SLAVEIO_ERRNR=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Last_IO_Errno: )[0-9]+$')
  SLAVEIO_ERRTXT=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Last_IO_Error: ).*$')
  SLAVESQL_STATUS=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Slave_SQL_Running: )(No|Yes)')
  SLAVESQL_ERRNR=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Last_SQL_Errno: )[0-9]+$')
  SLAVESQL_ERRTXT=$(echo ${MYSQL_RESPONSE} | grep --only-matching --perl-regexp --regexp='(?<=Last_SQL_Error: ).*$')
  IFS="${oldIFS}"

  if [ "${SLAVEIO_STATUS}" == "No" ]; then
    logerror "${FUNCNAME[0]}" "replica i/o is currently stopped and the error number '${SLAVEIO_ERRNR}' has been reported"
    logerror "${FUNCNAME[0]}" "replica i/o error message: '${SLAVEIO_ERRTXT}'"
  fi

  if [ "${SLAVESQL_STATUS}" == "No" ]; then
    logerror "${FUNCNAME[0]}" "replica sql is currently stopped and the error number '${SLAVESQL_ERRNR}' has been reported"
    logerror "${FUNCNAME[0]}" "replica sql error message: '${SLAVESQL_ERRTXT}'"
  fi

  if [ ${SLAVEIO_STATUS} == "Yes" ] && [ ${SLAVESQL_STATUS} == "Yes" ]; then
    loginfo "${FUNCNAME[0]}" "async replication active"
  else
    {{ if eq $.Values.scripts.logLevel "debug" }}logdebug "${FUNCNAME[0]}" "async replication summary: '${MYSQL_RESPONSE}'" {{ else }}loginfo "${FUNCNAME[0]}" "async replication not active" {{ end }}
  fi
}
