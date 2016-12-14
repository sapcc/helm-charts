{{- define "health_start_tpl" -}}
#!/bin/bash

# set some env variables from the openstack env properly based on env
. /ceilometer-bin/common-start

function process_config {
  cp /ceilometer-etc/healthcheck.conf /healthcheck.conf
}

function start_application {
  /healthcheck-loop.sh
}

process_config

start_application
{{- end -}}
