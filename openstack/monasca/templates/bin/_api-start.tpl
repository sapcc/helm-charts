{{- define "api_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {

  mkdir -p /etc/monasca
  cp /monasca-etc-base/api-api-config.conf  /etc/monasca/api-config.conf
  cp /monasca-etc-base/api-api-config.ini  /etc/monasca/api-config.ini
}

function start_application {

  exec /usr/share/python/monasca-api/bin/gunicorn -k eventlet --worker-connections=2000 --backlog=1000 --paste /etc/monasca/api-config.ini
}

process_config

start_application
{{ end }}
