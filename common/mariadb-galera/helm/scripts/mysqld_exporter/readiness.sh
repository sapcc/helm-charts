#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function checkmysqlexportermetrics {
  CURL_RESPONSE=$(curl --max-time ${WAIT_SECONDS} --retry ${MAX_RETRIES} --silent \
                    --write-out '\n{"curl":{"http_code":"%{http_code}","response_code":"%{response_code}","url":"%{url_effective}"}}\n' \
                    --header "Accept: text/plain" \
                    --request GET http://${CONTAINER_IP}:${WEB_LISTEN_PORT}${WEB_TELEMETRY_PATH-/metrics})
  CURL_STATUS=$?
  HTTP_STATUS=$(echo ${CURL_RESPONSE} | jq -r '. | select( .curl ) | .curl.http_code')
  CURL_OUTPUT=$(echo ${CURL_RESPONSE} | jq -c '. | select( .curl ) | .curl')
  HTTP_OUTPUT=$(echo ${CURL_RESPONSE} | grep '^mysqld_exporter_build_info')
  if [ ${CURL_STATUS} -ne 0 ]; then
    {{ if eq $.Values.scripts.logLevel "debug" }} logerror "${FUNCNAME[0]}" "MySQL exporter ${WEB_TELEMETRY_PATH-/metrics} query has been failed because of ${HTTP_OUTPUT}" {{ else }} logerror "${FUNCNAME[0]}" "MySQL exporter ${WEB_TELEMETRY_PATH-/metrics} query has been failed because of ${CURL_OUTPUT}" {{ end }}
    exit 1
  else
    loginfo "${FUNCNAME[0]}" "MySQL exporter query successful with http status code '${HTTP_STATUS}'"
    {{ if eq $.Values.scripts.logLevel "debug" }} logdebug "${FUNCNAME[0]}" "MySQL exporter query done with '${HTTP_OUTPUT}'" {{ else }} loginfo "${FUNCNAME[0]}" "MySQL exporter query done with http status code '${HTTP_STATUS}'" {{ end }}
  fi
}

checkmysqlexportermetrics
