#!/bin/bash

function process_config {

  mkdir /var/lib/grafana/etc
  cp /grafana-etc/grafana.ini /var/lib/grafana/etc/grafana.ini
  cp /grafana-etc/ldap.toml /var/lib/grafana/etc/ldap.toml

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
  # install sapcc/grafana-prometheus-alertmanager-datasource
  grafana-cli --pluginUrl https://github.com/sapcc/grafana-prometheus-alertmanager-datasource/archive/master.zip plugins install prometheus-alertmanager
  # setup the datasources and dashboards if the setup script exists
  # wait a moment until grafana is up and write to stdout and logfile in parallel
  if [ -f /grafana-bin/grafana-initial-setup ]; then
  # no ss commnd in the new grafana container, so we have to use curl to check ...
  #    (while ss -lnt | awk '$4 ~ /:{{.Values.grafana.port.public}}$/ {exit 1}'; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana/initial-setup.log &
       (while [ `curl -s http://localhost:3000 > /dev/null ; echo $?` != "0" ]; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana/initial-setup.log &
  fi
  # strange log config to get no file logging according to https://github.com/grafana/grafana/issues/5018
  cd /usr/share/grafana
  exec /usr/share/grafana/bin/grafana-server -config /var/lib/grafana/etc/grafana.ini --homepath /usr/share/grafana cfg:default.log.mode=console

}

process_config

start_application
