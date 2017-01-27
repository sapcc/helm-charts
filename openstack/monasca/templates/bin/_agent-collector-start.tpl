#!/bin/bash

# common initialization
. /monasca-bin/agent-start

function process_config {
  process_config_common

  # copy plugin configs
  for config in $MONASCA_AGENT_CHECKS; do
    config_filename=$(echo $config | tr '_' '-')
    cp /monasca-etc-base/agent-conf.d-${config_filename}.yaml /etc/monasca/agent/conf.d/$config.yaml
  done
}

function start_application {
  # wait for forwarder to come up
  . /monasca-bin/agent-forwarder-prereq

  start_application_common

  # start the actual process
  exec /usr/share/python/monasca-agent/bin/monasca-collector foreground
}

process_config

start_application
