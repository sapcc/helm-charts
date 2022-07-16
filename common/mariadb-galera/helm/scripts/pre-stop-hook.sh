#!/usr/bin/env bash
set +e
set -u
set -o pipefail

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
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

function checkgaleralocalstate {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" --batch --skip-column-names | grep --silent 'Synced'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node in sync with the cluster'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node not synced with the cluster'
    exit 1
  fi
}

function checkgaleraclusterstate {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_cluster_status';" --batch --skip-column-names | grep --silent 'Primary'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node reports a working cluster status'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node reports a not working cluster status'
    exit 1
  fi
}

function checkgaleranodeconnected {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_connected';" --batch --skip-column-names | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node connected to other cluster nodes'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node not connected to other cluster nodes'
    exit 1
  fi
}

function shutdowngaleranode {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHUTDOWN WAIT FOR ALL SLAVES;"
  if [ $? -eq 0 ]; then
    loginfo "${FUNCNAME[0]}" 'MariaDB Galera node shutdown successful'
  else
    logerror "${FUNCNAME[0]}" 'MariaDB Galera node shutdown failed'
    exit 1
  fi
}

function resetseqnoconfigmap {
  local int
  local CONFIGMAP_NAME=galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
  IFS=$'\t' SEQNO=($(mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
  IFS="${oldIFS}"

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}"  "Reset configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time {{ $.Values.readinessProbe.timeoutSeconds }} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.seqno\":\"\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${HTTP_OUTPUT}" {{ else }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with '${HTTP_OUTPUT}'" {{ else }} loginfo "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with http status code '${HTTP_STATUS}'" {{ end }}
}

function resetprimarystatusconfigmap {
  local int
  local CONFIGMAP_NAME=galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "Reset configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time {{ $.Values.readinessProbe.timeoutSeconds }} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.primary\":\"\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${HTTP_OUTPUT}" {{ else }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with '${HTTP_OUTPUT}'" {{ else }} loginfo "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with http status code '${HTTP_STATUS}'" {{ end }}
}

function resetrunningconfigmap {
  local int
  local CONFIGMAP_NAME=galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "Reset configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time {{ $.Values.readinessProbe.timeoutSeconds }} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.running\":\"\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${HTTP_OUTPUT}" {{ else }} echo "configmap '${CONFIGMAP_NAME}' reset has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with '${HTTP_OUTPUT}'" {{ else }} loginfo "${FUNCNAME[0]}" "configmap '${CONFIGMAP_NAME}' reset done with http status code '${HTTP_STATUS}'" {{ end }}
}

loginfo "null" "preStop hook started"
checkgaleraclusterstate
checkgaleranodeconnected
checkgaleralocalstate
resetseqnoconfigmap
resetprimarystatusconfigmap
resetrunningconfigmap
loginfo "null" "preStop hook done"
