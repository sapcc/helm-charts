#!/bin/bash

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  set -e

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  unset http_proxy https_proxy all_proxy no_proxy
  
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
