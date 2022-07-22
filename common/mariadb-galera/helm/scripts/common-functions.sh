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
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.${SCOPE}\":\"${CONTAINER_NAME}:${CONTENT}\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
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
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp --user=root --host=localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.application }} --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API usable'
  else
    echo 'MariaDB MySQL API not usable'
    exit 1
  fi
}

function checkdbk8sservicelogon {
  local ONLY_RETURN_STATUS=${1-false}

  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=mariadb-galera-fe.database.svc.cluster.local --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.application }} --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
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
