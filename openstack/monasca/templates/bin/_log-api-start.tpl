{{- define "log_api_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {

  mkdir -p /etc/monasca
  cp /monasca-etc-log/log-api-log-api-config.conf  /etc/monasca/log-api-config.conf
  cp /monasca-etc-log/log-api-log-api-config.ini  /etc/monasca/log-api-config.ini

  sed "s,KAFKA_CONSUMER_ID,${KUBE_POD_NAME},g" -i /etc/monasca/log-api-config.conf
}

function start_application {

  exec /usr/share/python/monasca-log-api/bin/gunicorn -k eventlet --worker-connections=2000 --backlog=1000 --paste /etc/monasca/log-api-config.ini

}

process_config

start_application
{{ end }}
