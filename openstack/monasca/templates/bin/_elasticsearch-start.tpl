#!/bin/bash

# set some env variables from the openstack env properly based on env
. /container.init/common.sh
chmod +x /container.init/*

function process_config {
  cp /monasca-etc-log/elasticsearch-elasticsearch.yaml /elasticsearch/config/elasticsearch.yaml
  cp /monasca-etc-log/elasticsearch-logging.yaml /elasticsearch/config/logging.yaml
}

function start_application {

  # provision elasticsearch user
  # TODO: why not done in image?
  unset http_proxy https_proxy all_proxy ftp_proxy no_proxy
  addgroup sudo
  groupadd elasticsearch
  useradd -g  elasticsearch elasticsearch
  adduser elasticsearch sudo
  chown -R elasticsearch:elasticsearch /elasticsearch /data
  # permit sudo w/o password for all users (TODO: why?)
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

  # set environment, these are referenced in the ES config files (no manual substitution needed)
  # TODO: who is setting these from outside?
  export NODE_MASTER=${NODE_MASTER:-true}
  export NODE_DATA=${NODE_DATA:-true}
  export HTTP_ENABLE=${HTTP_ENABLE:-true}
  export MULTICAST=${MULTICAST:-true}

  if [ "$ES_HEAP_SIZE" = "" ]; then
     export ES_HEAP_SIZE=10g
  fi

  # enable resync (again, it is disabled by the stop script)
  (sleep 180; curl -u {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} -XPUT localhost:{{.Values.monasca_elasticsearch_port_internal}}/_cluster/settings -d '{"transient": { "cluster.routing.allocation.enable": "all" } }' && curl -u {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}} -XPUT 'http://localhost:{{.Values.monasca_elasticsearch_port_internal}}/_template/logstash' -d "@/monasca-etc-log/es-data-logstash.schema.json") &

  # run
  echo "Starting ElasticSearch with lock /data/container.lock"
  exec chpst -u elasticsearch -L /data/container.lock /elasticsearch/bin/elasticsearch 
}

process_config

start_application
