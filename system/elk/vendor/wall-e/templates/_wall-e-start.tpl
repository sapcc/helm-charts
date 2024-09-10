#!/bin/bash

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8

  echo "INFO: setting discovery.zen.minimum_master_nodes to 2"
  curl -s -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} --header "content-type: application/JSON" -XPUT "http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/_cluster/settings" -d '{"transient": { "discovery.zen.minimum_master_nodes": 2 }}'


  # create Kibana indexes for all log indexes, index-pattern file has to be in directory files
  cd /wall-e-etc/ && ls -la

  for i in $(ls *-index-pattern.json|awk -F\- '{ print $1 }')
  do
    echo "setting kibana index mapping for index $i"
    curl --header "content-type: application/JSON" --fail -XGET -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} "http://{{.Values.kibana_service}}:{{.Values.kibana_port_public}}/api/saved_objects/index-pattern/${i}-*"
   if [ $? -eq 0 ]
   then
     echo "index ${i} already exists in Kibana"
     curl -XPOST --header "content-type: application/JSON" -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} "http://{{.Values.kibana_service}}:{{.Values.kibana_port_public}}/api/kibana/settings/defaultIndex" -H "kbn-xsrf: true" -d "{\"value\":\"logstash-*\"}"

   else
     echo "INFO: creating index-pattern in Kibana for $i logs"
     curl -XPOST --header "content-type: application/JSON" -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} "http://{{.Values.kibana_service}}:{{.Values.kibana_port_public}}/api/saved_objects/index-pattern/${i}-*" -H "kbn-xsrf: true" -d @${i}-index-pattern.json

     curl -XPOST --header "content-type: application/JSON" -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} "http://{{.Values.kibana_service}}:{{.Values.kibana_port_public}}/api/kibana/settings/defaultIndex" -H "kbn-xsrf: true" -d "{\"value\":\"logstash-*\"}"
    fi
  done

  echo "INFO: deleting old indexes in case we run out of space"
  /curator/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml

  echo "setting default index pattern for a couple of indexes"
  for i in "kubernikus" "scaleout" "virtual" "syslog" "jump" "jaeger-span" "jaeger-service"

  do
    curl -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} -XPUT http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/_template/${i} -H 'Content-Type: application/json' -d @/wall-e-etc/$i.json
  done

  echo "INFO: setting up cron jobs for index creation and purging"
  cat <(crontab -l) <(echo "0 1,3,5,7,9,11,13,15,17,19,21,23 * * * export LC_ALL=C.UTF-8; export LANG=C.UTF-8; /curator/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  echo "INFO: delete all kubernikus indexes from the future"
  cat <(crontab -l) <(echo "0 1,13 * * * export LC_ALL=C.UTF-8; export LANG=C.UTF-8; curl -s -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/_aliases?pretty=true|grep kuber|grep '20[3-9]'|awk '{ print \$1}'|tr -d '\"'|xargs -I {} curl -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} -X DELETE "http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/{}?pretty"  > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "0 1,13 * * * export LC_ALL=C.UTF-8; export LANG=C.UTF-8; curl -s -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/_aliases?pretty=true|grep kuber|grep '21[0-9]'|awk '{ print \$1}'|tr -d '\"'|xargs -I {} curl -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} -X DELETE "http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/{}?pretty" > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "0 1,13 * * * export LC_ALL=C.UTF-8; export LANG=C.UTF-8; curl -s -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/_aliases?pretty=true|grep kuber|grep '202[4-9]'|awk '{ print \$1}'|tr -d '\"'|xargs -I {} curl -u {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}} -X DELETE "http://{{.Values.endpoint_host_internal}}:{{.Values.http_port}}/{}?pretty" > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  echo "INFO: starting cron in foreground"
  exec cron -f

}

process_config

start_application
