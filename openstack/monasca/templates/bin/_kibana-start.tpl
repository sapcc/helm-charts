#!/bin/bash

set -e

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {

  export KIBANA_VERSION=$(cat /KIBANA_VERSION.env)
  export KIBANA_CONF_FILE="/opt/kibana-${KIBANA_VERSION}-linux-x64/config/kibana.yml"

  cp /monasca-etc-log/kibana-kibana.yml ${KIBANA_CONF_FILE}

}

function start_application {

  export KIBANA_ES_URL=${KIBANA_ES_URL:-http://localhost:{{.Values.monasca_elasticsearch_port_internal}}}


  if [ -n "${KIBANA_INDEX}" ]; then
      echo "setting index!"
      sed -i "s;^kibana_index:.*;kibana_index: ${KIBANA_INDEX};" "${KIBANA_CONF_FILE}"
  fi

  #wget https://github.com/FujitsuEnablingSoftwareTechnologyGmbH/fts-keystone/archive/master.zip -O /tmp/master.zip && unzip /tmp/master.zip -d /opt/kibana-${KIBANA_VERSION}-linux-x64/installedPlugins/
  #wget https://github.com/hmalphettes/kibana-auth-plugin/archive/master.zip -O /tmp/master.zip && unzip /tmp/master.zip -d /opt/kibana-${KIBANA_VERSION}-linux-x64/installedPlugins/

  #npm i hapi-auth-cookie

  #export LOCAL_AUTH_LOGINS=kibana:kibana

  echo "Starting Kibana"
  exec /opt/kibana-${KIBANA_VERSION}-linux-x64/bin/kibana

}

process_config

start_application
