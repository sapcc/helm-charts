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
  # install some plugins
  grafana-cli plugins install vonage-status-panel
  # since grafana version 4.6.2 the histogram feature is part of the normal graph in the axes tab, so this plugin is no longer needed
  # grafana-cli plugins install mtanda-histogram-panel
  grafana-cli plugins install camptocamp-prometheus-alertmanager-datasource
  # setup the datasources and dashboards if the setup script exists
  # wait a moment until grafana is up and write to stdout and logfile in parallel
  if [ -f /grafana-bin/grafana-initial-setup ]; then
    (while ss -lnt | awk '$4 ~ /:{{.Values.grafana.port.public}}$/ {exit 1}'; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana-initial-setup.log &
  fi
  # strange log config to get no file logging according to https://github.com/grafana/grafana/issues/5018
  cd /usr/share/grafana
  exec /usr/sbin/grafana-server -config /etc/grafana/grafana.ini cfg:default.log.mode=console

}

process_config

start_application
