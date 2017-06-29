#!/bin/bash

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  set -e

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  unset http_proxy https_proxy all_proxy no_proxy
  export ELK_ELASTICSEARCH_MASTER_PROJECT_ID={{.Values.elk_elasticsearch_master_project_id}}
  cp -f /grafana-content/grafana-content/kibana/search.json /search.json
  cp -f /grafana-content/grafana-content/kibana/vizualization.json /vizualization.json
  cp -f /grafana-content/grafana-content/kibana/dashboard.json /dashboard.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /search.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /vizualization.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /dashboard.json
  

  curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_cluster/settings" -d '{"transient": { "discovery.zen.minimum_master_nodes": 2 }}'

  curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/{{.Values.elk_elasticsearch_master_project_id}}" -d "@/grafana-content/grafana-content/elasticsearch/{{.Values.elk_elasticsearch_master_project_id}}.json"

  /node_modules/elasticdump/bin/elasticdump \
      --input=/search.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data

  /node_modules/elasticdump/bin/elasticdump \
      --input=/vizualization.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data
  
  /node_modules/elasticdump/bin/elasticdump \
      --input=/dashboard.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data
  
  cat <(crontab -l) <(echo "0 6 * * * /usr/local/bin/curator --config /wall-e-etc/curator.yml  /wall-e-etc/delete_indices.yml > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "0 3 * * * . /wall-e-bin/create-kibana-audit-indexes.sh  > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  exec cron -f 

}

process_config

start_application
