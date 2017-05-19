#!/bin/bash

set -e


function process_config {

  export KIBANA_CONF_FILE="/opt/kibana/config/kibana.yml"

  cp /monasca-etc/kibana-kibana.yml ${KIBANA_CONF_FILE}

}

function start_application {

  export KIBANA_ES_URL=${KIBANA_ES_URL:-http://localhost:9200}


  if [ -n "${KIBANA_INDEX}" ]; then
      echo "setting index!"
      sed -i "s;^kibana_index:.*;kibana_index: ${KIBANA_INDEX};" "${KIBANA_CONF_FILE}"
  fi


  echo "Starting Kibana"
  exec /opt/kibana/bin/kibana

}

process_config

start_application
