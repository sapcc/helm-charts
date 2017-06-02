#!/bin/bash

set -e

# set some env variables from the openstack env properly based on env
. /kibana-bin/common-start

function process_config {

  export KIBANA_VERSION=$(cat /KIBANA_VERSION.env)
  export KIBANA_CONF_FILE="/opt/kibana/config/kibana.yml"

  cp /kibana-etc/kibana.yml ${KIBANA_CONF_FILE}

}

function start_application {

  export KIBANA_ES_URL=${KIBANA_ES_URL:-http://localhost:{{.Values.elk_elasticsearch_port_internal}}}


  if [ -n "${KIBANA_INDEX}" ]; then
      echo "setting index!"
      sed -i "s;^kibana_index:.*;kibana_index: ${KIBANA_INDEX};" "${KIBANA_CONF_FILE}"
  fi


  echo "Starting Kibana"
  exec /opt/kibana/bin/kibana

}

process_config

start_application
