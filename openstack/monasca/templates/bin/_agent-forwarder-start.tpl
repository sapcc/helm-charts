{{- define "agent_forwarder_start_tpl" -}}
#!/bin/bash

# common initialization
. /container.init/agent-start

function process_config {
  process_config_common
}

function start_application {
  start_application_common

  # start the actual process
  exec /usr/share/python/monasca-agent/bin/monasca-forwarder
}

process_config

start_application
{{ end }}
