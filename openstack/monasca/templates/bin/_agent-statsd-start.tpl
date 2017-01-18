#!/bin/bash

# common initialization
. /monasca-bin/agent-start

function process_config {
  process_config_common
}

function start_application {
  # wait for forwarder to come up
  . /monasca-bin/agent-forwarder-prereq

  start_application_common

  # start the actual process
  exec /usr/share/python/monasca-agent/bin/monasca-statsd
}

process_config

start_application
