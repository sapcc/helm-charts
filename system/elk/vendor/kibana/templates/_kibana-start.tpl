#!/bin/bash

set -e

function process_config {

  unset http_proxy https_proxy all_proxy no_proxy
  export KIBANA_VERSION=$(cat /KIBANA_VERSION.env)
  export KIBANA_CONF_FILE="/opt/kibana/config/kibana.yml"

  cp /kibana-etc/kibana.yml ${KIBANA_CONF_FILE}

}

function start_application {

#  export KIBANA_ES_URL=${KIBANA_ES_URL:-http://localhost:{{.Values.elk_elasticsearch_http_port}}}


#  if [ -n "${KIBANA_INDEX}" ]; then
#      echo "setting index!"
#      sed -i "s;^kibana_index:.*;kibana_index: ${KIBANA_INDEX};" "${KIBANA_CONF_FILE}"
#  fi


  echo "Starting Kibana"
  export no_proxy=$no_proxy,100.
  exec /opt/kibana/bin/kibana --allow-root

}

process_config

start_application
