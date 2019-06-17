#!/bin/bash

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  unset http_proxy https_proxy all_proxy no_proxy
  
  echo "INFO: setting discovery.zen.minimum_master_nodes to 2"  
  curl -s -u {{.Values.global.admin_user}}:{{.Values.global.admin_password}} --header "content-type: application/JSON" -XPUT "http://{{.Values.global.endpoint_host_internal}}:{{.Values.global.http_port}}/_cluster/settings" -d '{"transient": { "discovery.zen.minimum_master_nodes": 2 }}'


  # create Kibana indexes for all log indexes, index-pattern file has to be in directory files 
  cd /wall-e-etc/ && ls -la
  
  for i in $(ls *-index-pattern.json|awk -F\- '{ print $1 }')
  do
    echo "setting kibana index mapping for index $i"
    curl --header "content-type: application/JSON" --fail -XGET -u {{.Values.global.admin_user}}:{{.Values.global.admin_password}} "http://{{.Values.global.kibana_service}}:{{.Values.global.kibana_port_public}}/api/saved_objects/index-pattern/${i}-*"
   if [ $? -eq 0 ]
   then
     echo "index ${i} already exists in Kibana"

   else
     echo "INFO: creating index-pattern in Kibana for $i logs"
     curl -XPOST --header "content-type: application/JSON" -u {{.Values.global.admin_user}}:{{.Values.global.admin_password}} "http://{{.Values.global.kibana_service}}:{{.Values.global.kibana_port_public}}/api/saved_objects/index-pattern/${i}-*" -H "kbn-xsrf: true" -d @${i}-index-pattern.json

    fi
  done

  echo "INFO: deleting old indexes in case we run out of space"
  /usr/local/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml
  
  echo "INFO: setting up cron jobs for index creation and purging"
  cat <(crontab -l) <(echo "0 6 * * * /usr/local/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  echo "INFO: starting cron in foreground"
  exec cron -f 

}

process_config

start_application
