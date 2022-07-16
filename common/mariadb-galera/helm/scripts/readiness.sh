#!/usr/bin/env bash
set +e
set -u
set -o pipefail

oldIFS="${IFS}"
BASE=/opt/${SOFTWARE_NAME}
DATADIR=${BASE}/data
MAX_RETRIES=10
WAIT_SECONDS=6

function checkdblogon {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="STATUS;" | grep 'Server version:' | grep --silent "${SOFTWARE_VERSION}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API usable'
  else
    echo 'MariaDB MySQL API not usable'
    exit 1
  fi
}

function checkgaleraclusterstatus {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_cluster_status';" | grep 'wsrep_cluster_status' | grep --silent 'Primary'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node reports a working cluster status'
  else
    echo 'MariaDB Galera node reports a not working cluster status'
    exit 1
  fi
}

function checkgaleranodejoinstatus {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_local_state_comment';" | grep 'wsrep_local_state_comment' | grep --invert-match --silent 'Initialized'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node has not failed to join the cluster'
  else
    echo 'MariaDB Galera node has failed to join the cluster'
    exit 1
  fi
}

function checkgaleranodeconnectstatus {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_connected';" | grep 'wsrep_connected' | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera node connected to other cluster nodes'
  else
    echo 'MariaDB Galera node not connected to other cluster nodes'
    exit 1
  fi
}

function checkgaleraready {
  mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_ready';" | grep 'wsrep_ready' | grep --silent 'ON'
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera ready for queries'
  else
    echo 'MariaDB Galera not ready for queries'
    exit 1
  fi
}

function updateseqnoconfigmap {
  local int
  local CONFIGMAP_NAME=galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
  IFS=$'\t' SEQNO=($(mysql --defaults-file=/opt/${SOFTWARE_NAME}/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
  IFS="${oldIFS}"

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    echo "Update configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time {{ $.Values.readinessProbe.timeoutSeconds }} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.seqno\":\"${CONTAINER_NAME}:${SEQNO[1]}\ntimestamp:$(date +%s)\n\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' update has been failed because of ${HTTP_OUTPUT}" {{ else }} echo "configmap '${CONFIGMAP_NAME}' update has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    echo "configmap '${CONFIGMAP_NAME}' update has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' update done with '${HTTP_OUTPUT}'" {{ else }} echo "configmap '${CONFIGMAP_NAME}' update done with http status code '${HTTP_STATUS}'" {{ end }}
}

function updateprimarystatusconfigmap {
  local int
  local CONFIGMAP_NAME=galerastatus
  local KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    echo "Update configmap '${CONFIGMAP_NAME}' (${int} retries left)"
    CURL_RESPONSE=$(curl --max-time {{ $.Values.readinessProbe.timeoutSeconds }} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                    --header "Authorization: Bearer ${KUBE_TOKEN}" --header "Accept: application/json" --header "Content-Type: application/strategic-merge-patch+json" \
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.primary\":\"${CONTAINER_NAME}:true\ntimestamp:$(date +%s)\n\"}}" \
                    --request PATCH https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/namespaces/${NAMESPACE}/configmaps/${CONFIGMAP_NAME})
    CURL_STATUS=$?
    HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
    CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
    HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | jq '. | select( .kind )')
    if [ ${CURL_STATUS} -ne 0 ]; then
      {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' update has been failed because of ${HTTP_OUTPUT}" {{ else }} echo "configmap '${CONFIGMAP_NAME}' update has been failed because of ${CURL_OUTPUT}" {{ end }}
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    echo "configmap '${CONFIGMAP_NAME}' update has been finally failed"
    exit 1
  fi
  {{ if eq $.Values.logLevel "debug" }} echo "configmap '${CONFIGMAP_NAME}' update done with '${HTTP_OUTPUT}'" {{ else }} echo "configmap '${CONFIGMAP_NAME}' update done with http status code '${HTTP_STATUS}'" {{ end }}
}

checkdblogon
checkgaleraclusterstatus
checkgaleranodejoinstatus
checkgaleranodeconnectstatus
checkgaleraready
updateseqnoconfigmap
updateprimarystatusconfigmap
