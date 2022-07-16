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
  mysql --defaults-file=/opt/mariadb/etc/my.cnf --protocol=tcp -u root -h localhost --port=${MYSQL_PORT} --batch --connect-timeout={{ $.Values.livenessProbe.timeoutSeconds }} --execute="SHOW DATABASES;" | grep --silent 'mysql'
  if [ $? -eq 0 ]; then
    echo 'MariaDB MySQL API reachable'
  else
    echo 'MariaDB MySQL API not reachable'
    exit 1
  fi
}

function checkgaleraport {
  timeout {{ $.Values.livenessProbe.timeoutSeconds }} bash -c "</dev/tcp/${CONTAINER_IP}/${GALERA_PORT}"
  if [ $? -eq 0 ]; then
    echo 'MariaDB Galera API reachable'
  else
    echo 'MariaDB Galera API not reachable'
    exit 1
  fi
}

function updaterunningconfigmap {
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
                    --data "{\"kind\":\"ConfigMap\",\"apiVersion\":\"v1\",\"data\":{\"${CONTAINER_NAME}.running\":\"${CONTAINER_NAME}:true\ntimestamp:$(date +%s)\n\"}}" \
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
checkgaleraport
updaterunningconfigmap
