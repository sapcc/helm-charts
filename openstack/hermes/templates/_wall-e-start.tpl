#!/bin/bash

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  set -e

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  unset http_proxy https_proxy all_proxy no_proxy
  
  echo "INFO: setting up audit, .kibana, .monitoring-data-2 and .monitoring-es-2 templates without replicas for a green status"
  curl -XPUT 'http://elasticsearch:9200/_template/.kibana' -d@/wall-e-etc/dot-kibana.json
  curl -XPUT 'http://elasticsearch:9200/_template/.monitoring-data-2' -d@/wall-e-etc/dot-monitoring-data-2.json
  curl -XPUT 'http://elasticsearch:9200/_template/.monitoring-es-2' -d@/wall-e-etc/dot-monitoring-es-2.json
  # delete them, so that they will be recreated from the proper new template
  curl -XDELETE 'http://elasticsearch:9200/.kibana'
  curl -XDELETE 'http://elasticsearch:9200/.monitoring-data-2'
  curl -XDELETE 'http://elasticsearch:9200/.monitoring-es-2'

  # run the creation of the index patterns and the index retention cleanup deletion once on startup and put them into cron to run once per night afterwards
  echo "INFO: creating the audit indexes in kibana"
  . /wall-e-bin/create-kibana-indexes.sh
  echo ""
  echo "INFO: deleting old indexes in case we run out of space"
  /usr/local/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml

  echo "INFO: setting up cron jobs for index creation and purging"
  cat <(crontab -l) <(echo "0 3 * * * . /wall-e-bin/create-kibana-indexes.sh  > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "0 6 * * * /usr/local/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  echo "INFO: starting cron in foreground"
  exec cron -f

}

process_config

start_application
