#!/bin/bash

# common initialization
. /monasca-bin/agent-start

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
