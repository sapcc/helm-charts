{{- define "health_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {
  cp /monasca-etc-base/health-healthcheck.conf /healthcheck.conf
}

function start_application {
  /healthcheck-loop.sh
}

process_config

start_application
{{ end }}
