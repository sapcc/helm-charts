#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common-start

# get the persister config file and replace with the secrets inside of it
function process_config {
  mkdir -p /etc/monasca

  cp /monasca-etc-base/persister-persister.conf /etc/monasca/persister.conf

  # use Kubernetes IDs for some attributes
  sed "s,KAFKA_CONSUMER_ID,${KUBE_POD_NAME},g" -i /etc/monasca/persister.conf
}

function start_application {
  exec /usr/share/python/monasca-persister/bin/monasca-persister
}

function diagnose_application {
  echo "Persister could not be started: dump config"
  cat /etc/monasca/persister.conf | grep -v "password"
}

process_config

start_application

diagnose_application
