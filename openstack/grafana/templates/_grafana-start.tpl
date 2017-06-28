#!/bin/bash

function process_config {

  cp /grafana-etc/grafana.ini /etc/grafana/grafana.ini
  cp /grafana-etc/ldap.toml /etc/grafana/ldap.toml

}

function start_application {

  # Set cluster region
  export CLUSTER_REGION={{.Values.global.region}}
  # Set Grafana admin/local username & password
  export GF_SECURITY_ADMIN_USER={{.Values.grafana.admin.user}}
  export GF_SECURITY_ADMIN_PASSWORD={{.Values.grafana.admin.password}}
  export GRAFANA_LOCAL_USER={{.Values.grafana.local.user}}
  export GRAFANA_LOCAL_PASSWORD={{.Values.grafana.local.password}}
  # Set flags for wiping/loading datasources & dashboards
  export GRAFANA_WIPE_DATASOURCES={{.Values.grafana.wipe.datasources}}
  export GRAFANA_LOAD_DATASOURCES={{.Values.grafana.load.datasources}}
  export GRAFANA_WIPE_DASHBOARDS={{.Values.grafana.wipe.dashboards}}
  export GRAFANA_LOAD_DASHBOARDS={{.Values.grafana.load.dashboards}}
  # Set elasticsearch user and password required for elasticsearch datasource
  export ELASTICSEARCH_USER={{.Values.elasticsearch.admin.user}}
  export ELASTICSEARCH_PASSWORD={{.Values.elasticsearch.admin.password}}
  export ELASTICSEARCH_MASTER_PROJECT_ID={{.Values.elasticsearch.master_project_id}}
  export ELASTICSEARCH_VERSION={{.Values.elasticsearch.version}}
  # install some plugins
  grafana-cli plugins install vonage-status-panel
  grafana-cli plugins install mtanda-histogram-panel
  # setup the datasources and dashboards if the setup script exists
  # wait a moment until grafana is up and write to stdout and logfile in parallel
  if [ -f /grafana-content/grafana-content/scripts/datasources-dashboards.sh ]; then
    (while ss -lnt | awk '$4 ~ /:{{.Values.grafana.port.public}}$/ {exit 1}'; do sleep 5; done; bash /grafana-content/grafana-content/scripts/datasources-dashboards.sh ) 2>&1 | tee /var/log/datasources-dashboards.log &
  fi
  # strange log config to get no file logging according to https://github.com/grafana/grafana/issues/5018
  cd /usr/share/grafana
  exec /usr/sbin/grafana-server -config /etc/grafana/grafana.ini cfg:default.log.mode=console

}

process_config

start_application
