#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {
  cp /monasca-etc-base/health-healthcheck.conf /healthcheck.conf
}

function start_application {
  /healthcheck-loop.sh
}

process_config

start_application
