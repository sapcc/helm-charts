#!/bin/bash

function process_config {
  cp -f /es-etc/elasticsearch.yml /elasticsearch/config/elasticsearch.yml
  cp -f /es-etc/readonlyrest.yml /elasticsearch/config/readonlyrest.yml
  cp -f /es-etc/log4j2.properties /elasticsearch/config/log4j2.properties
  cp -f /es-etc/jvm.options /elasticsearch/config/jvm.options
}

function start_application {

  # provision elasticsearch user
  # TODO: why not done in image?
  unset http_proxy https_proxy all_proxy ftp_proxy no_proxy
  chown -R elasticsearch:elasticsearch /elasticsearch /data

  # set environment, these are referenced in the ES config files (no manual substitution needed)
  # TODO: who is setting these from outside?
  export NODE_MASTER=${NODE_MASTER:-true}
  export NODE_DATA=${NODE_DATA:-true}
  export HTTP_ENABLE=${HTTP_ENABLE:-true}
  export MULTICAST=${MULTICAST:-true}
  unset http_proxy https_proxy all_proxy no_proxy

  if [ "$ES_JAVA_OPTS" = "" ]; then
     export ES_JAVA_OPTS="-Xms10g -Xmx10g"
  fi

  # enable resync (again, it is disabled by the stop script)
  (sleep 180; curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT localhost:{{.Values.elk_elasticsearch_port_internal}}/_cluster/settings -d '{"transient": { "cluster.routing.allocation.enable": "all" } }') &

  # run
  echo "Starting ElasticSearch with lock /data/container.lock"
  exec chpst -u elasticsearch -L /data/container.lock /elasticsearch/bin/elasticsearch 
}

process_config

start_application
