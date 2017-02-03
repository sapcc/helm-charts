#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {
  #  get the config monasca-thesh config file and replace with the secrets inside of it
  cp /monasca-etc/storm-thresh-storm.yaml /opt/storm/current/conf/storm.yaml
  cp -f /monasca-etc/storm-thresh-worker.xml /opt/storm/current/log4j2/worker.xml
  cp -f /monasca-etc/storm-thresh-cluster.xml /opt/storm/current/log4j2/cluster.xml


}

function start_application {
  # Storm start script expect this to be set
  export PYTHON=/usr/bin/python2.7
  
  exec /opt/storm/current/bin/storm supervisor
}

set -e

process_config

start_application
