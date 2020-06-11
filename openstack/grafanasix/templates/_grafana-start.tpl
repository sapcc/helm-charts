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
  grafana-cli plugins install grafana-piechart-panel
  grafana-cli plugins install flant-statusmap-panel
  grafana-cli plugins install natel-discrete-panel
  grafana-cli plugins install vonage-status-panel
  grafana-cli plugins install blackmirror1-statusbygroup-panel
  grafana-cli plugins install digrich-bubblechart-panel
  grafana-cli plugins install briangann-datatable-panel
  # since grafana version 4.6.2 the histogram feature is part of the normal graph in the axes tab, so this plugin is no longer needed
  # grafana-cli plugins install mtanda-histogram-panel
  grafana-cli plugins install grafana-worldmap-panel
  grafana-cli plugins install yesoreyeram-boomtable-panel
  # install sapcc/grafana-prometheus-alertmanager-datasource
  grafana-cli --pluginUrl https://github.com/sapcc/grafana-prometheus-alertmanager-datasource/archive/master.zip plugins install prometheus-alertmanager
  # install sapcc/Grafana_Status_panel
  grafana-cli --pluginUrl https://github.com/sapcc/Grafana_Status_panel/archive/master.zip plugins install cc-status-panel
  # setup the datasources and dashboards if the setup script exists
  # wait a moment until grafana is up and write to stdout and logfile in parallel
  if [ -f /grafana-bin/grafana-initial-setup ]; then
  # no ss commnd in the new grafana container, so we have to use curl to check ...
  #  (while ss -lnt | awk '$4 ~ /:{{.Values.grafana.port.public}}$/ {exit 1}'; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana/initial-setup.log &
  # no curl commnd in the new grafana container, so we have to use wget to check ...
  #  (while [ `curl -s http://localhost:3000 > /dev/null ; echo $?` != "0" ]; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana/initial-setup.log &
    (while ! wget -q -O /dev/null http://localhost:3000; do sleep 5; done; bash /grafana-bin/grafana-initial-setup ) 2>&1 | tee /var/log/grafana/initial-setup.log &
  fi
  while [ ! -d /git/grafana-content/datasources-config ]; do
    echo "waiting 5 more seconds for the grafana-content to be mounted and synced via git-sync ..."
    sleep 5
  done
  # create an auto provisioning dir for grafana and copy the content from the git to it
  # the cp is required in order to be able to modify the datasources below, the dashboard
  # config references back to the dashboard-sources dir in the git repo directly
  mkdir -p /var/lib/grafana/provisioning
  # do not do the above if the are in author more - then we do not provision anything
  if [ "{{.Values.grafana.mode}}" != "author" ]; then
    rm -rf /var/lib/grafana/provisioning/dashboards
    cp -a /git/grafana-content/dashboards-config-{{.Values.grafana.mode}} /var/lib/grafana/provisioning/dashboards
  fi
  rm -rf /var/lib/grafana/provisioning/datasources
  mkdir -p /var/lib/grafana/provisioning/datasources
  cd /git/grafana-content/datasources-config
  for i in * ; do
    grep -qw "    tlsAuthWithCACert: true" $i
    ADD_CERTS_YN_LC=$?
    grep -qw "    tlsAuthWithCACert: True" $i
    ADD_CERTS_YN_UC=$?
    if [ "$ADD_CERTS_YN_LC" = "0" ] || [ "$ADD_CERTS_YN_UC" = "0" ]; then
      cat $i | grep -v "json object of data that will be encrypted" | grep -v secureJsonData > /var/lib/grafana/provisioning/datasources/$i
      echo "  # <string> json object of data that will be encrypted." >> /var/lib/grafana/provisioning/datasources/$i
      echo "  secureJsonData:" >> /var/lib/grafana/provisioning/datasources/$i
      if [ -f /grafana-ds-certs/cacert.crt ]; then
        echo '    tlsCACert: |' >> /var/lib/grafana/provisioning/datasources/$i
        cat /grafana-ds-certs/cacert.crt | sed 's/^/      /' >> /var/lib/grafana/provisioning/datasources/$i
      fi
      if [ -f /grafana-ds-certs/sso.crt ]; then
        echo '    tlsClientCert: |' >> /var/lib/grafana/provisioning/datasources/$i
        cat /grafana-ds-certs/sso.crt | sed 's/^/      /' >> /var/lib/grafana/provisioning/datasources/$i
      fi
      if [ -f /grafana-ds-certs/sso.key ]; then
        echo '    tlsClientKey: |' >> /var/lib/grafana/provisioning/datasources/$i
        cat /grafana-ds-certs/sso.key | sed 's/^/      /' >> /var/lib/grafana/provisioning/datasources/$i
      fi
    else
      cp -a $i /var/lib/grafana/provisioning/datasources
    fi
  done
  sed -i 's,__ALERTMANAGER_PASSWORD__,{{.Values.alertmanager.password}},g' /var/lib/grafana/provisioning/datasources/*
  sed -i 's,__PROMETHEUS_REGION__,{{.Values.global.region}},g' /var/lib/grafana/provisioning/datasources/*
  #for i in /var/lib/grafana/provisioning/datasources/elasticsearch* ; do
  #  echo "=== $i ==="
  #  cat $i
  #done
  # strange log config to get no file logging according to https://github.com/grafana/grafana/issues/5018
  cd /usr/share/grafana
  exec /usr/share/grafana/bin/grafana-server -config /var/lib/grafana/etc/grafana.ini --homepath /usr/share/grafana cfg:default.log.mode=console
}

process_config

start_application
