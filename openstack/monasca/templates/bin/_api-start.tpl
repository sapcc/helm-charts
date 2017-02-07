#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {

  mkdir -p /etc/monasca
  cp /monasca-etc/api-api-config.conf  /etc/monasca/api-config.conf
  cp /monasca-etc/api-api-config.ini  /etc/monasca/api-config.ini

  sed "s,KAFKA_CONSUMER_ID,${KUBE_POD_NAME},g" -i /etc/monasca/api-config.conf
}

function start_application {

  exec /usr/share/python/monasca-api/bin/gunicorn -k eventlet --worker-connections=2000 --backlog=1000 --paste /etc/monasca/api-config.ini
}

process_config

start_application
