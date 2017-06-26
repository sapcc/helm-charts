#!/bin/bash

# set some env variables from the openstack env properly based on env
function process_config {

  cp /grafana-etc/grafana.ini /etc/grafana/grafana.ini
  cp /grafana-etc/ldap.toml /etc/grafana/ldap.toml
  
  mkdir /dashboards
  cp -f /grafana-content/monasca-content/datasources-dashboards.sh /dashboards/datasources-dashboards.sh
  find /grafana-content/monasca-content/ -name "dashboards"|xargs -I {} find {} -name "*.json"|xargs -I {} echo cp \"{}\"  /dashboards/

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
  # setup the datasources and dashboards if the setup script exists
  # wait a moment until grafana is up and write to stdout and logfile in parallel
#  if [ -x /opt/grafana/datasources-dashboards.sh ]; then
#    (while netstat -lnt | awk '$4 ~ /:{{.Values.grafana.port.public}}$/ {exit 1}'; do sleep 5; done; /opt/grafana/datasources-dashboards.sh ) 2>&1 | tee /opt/grafana/datasources-dashboards.log &
##  fi

  if [ -f /var/lib/grafana/grafana.db ]; then
    echo "creating a backup of the grafana db at /var/lib/grafana/backup/grafana.db.`date +%Y%m%d%H%M%S`"
    mkdir -p /var/lib/grafana/backup
    cp /var/lib/grafana/grafana.db /var/lib/grafana/backup/grafana.db.`date +%Y%m%d%H%M%S`
    # keep only the last 20 backups to avoid the disk running over
    for i in `ls -tr /var/lib/grafana/backup/* | head -n -20`; do rm $i; done
  fi

  # strange log config to get no file logging according to https://github.com/grafana/grafana/issues/5018
  cd /usr/share/grafana
  exec /usr/sbin/grafana-server -config /etc/grafana/grafana.ini cfg:default.log.mode=console

}

process_config

start_application
