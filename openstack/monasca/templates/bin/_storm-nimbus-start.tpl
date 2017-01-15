#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

function process_config {
  #  get the config monasca-thesh config file and replace with the secrets inside of it
  cp /monasca-etc-storm-thresh/storm-thresh-storm.yaml /opt/storm/current/conf/storm.yaml
  cp /monasca-etc-storm-thresh/storm-thresh-thresh-config.yml /etc/monasca/thresh-config.yml
  cp -f /monasca-etc-storm-thresh/storm-thresh-cluster.xml /opt/storm/current/log4j2/cluster.xml
  cp -f /monasca-etc-storm-thresh/storm-thresh-worker.xml /opt/storm/current/log4j2/worker.xml

}

function start_application {
  # fail on error
  set -e

  # Storm start script expect this to be set
  export PYTHON=/usr/bin/python2.7
 
  /opt/zookeeper/bin/zkCli.sh -server zk:{{.Values.monasca_zookeeper_port_internal}} deleteall /storm
 
  ( sleep 20 && /opt/storm/current/bin/storm jar /opt/monasca/monasca-thresh.jar monasca.thresh.ThresholdingEngine /etc/monasca/thresh-config.yml thresh-cluster ) &
  
  echo "Start nimbus"
  exec /opt/storm/current/bin/storm nimbus
}


process_config

start_application
