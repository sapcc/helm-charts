MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}
MYSQL_SVC_CONNECT="mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host={{ (include "nodeNamePrefix" (dict "global" $ "component" "application")) }}-frontend.database.svc.cluster.local --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch"

#entrypoint-galera
# updateconfigmap "scope[seqno|running|primary]" "value[sequence number|true|false]" "output[Update|Reset]"
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
  local CONFIGMAP_NAME=galerastatus
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
    IFS=$'\t' SEQNOARRAY=($(mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp --user=root --host=localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.application }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
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
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp --user=root --host=localhost --port=${MYSQL_PORT} --database=mysql --wait --connect-timeout=${WAIT_SECONDS} --reconnect --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API usable'
  else
    echo 'MariaDB MySQL API not usable'
    exit 1
  fi
}

function checkdbk8sservicelogon {
  local ONLY_RETURN_STATUS=${1-false}

  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host={{ (include "nodeNamePrefix" (dict "global" $ "component" "application")) }}-frontend.database.svc.cluster.local --port=${MYSQL_PORT} --database=mysql --wait --connect-timeout=${WAIT_SECONDS} --reconnect --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
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
        if [ "$0" == "/opt/mariadb/bin/entrypoint-job.sh" ]; then
          ${MYSQL_SVC_CONNECT} --execute="${DB_CREATE} ${DB_NAME} CHARACTER SET = ${DB_CHARSET} COLLATE = ${DB_COLLATION} COMMENT '${DB_COMMENT}';"
        else
          mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --batch --execute="${DB_CREATE} ${DB_NAME} CHARACTER SET = ${DB_CHARSET} COLLATE = ${DB_COLLATION} COMMENT '${DB_COMMENT}';"
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
          if [ "$0" == "/opt/mariadb/bin/entrypoint-job.sh" ]; then
            ${MYSQL_SVC_CONNECT} --execute="DROP DATABASE IF EXISTS ${DB_NAME};"
          else
            mysql --defaults-file=${BASE}/etc/my.cnf --user=root --host=localhost --batch --execute="DROP DATABASE IF EXISTS ${DB_NAME};"
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
