#!/bin/bash

# set some env variables from the openstack env properly based on env
. /elk-bin/common-start

function process_config {

  echo "nothing to be done for process_config"

}

function start_application {

  set -e

  export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
  export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
  export elk_ELASTICSEARCH_MASTER_PROJECT_ID={{.Values.elk_elasticsearch_master_project_id}}
  cp -f /elk-content/elk-content/kibana/search.json /search.json
  cp -f /elk-content/elk-content/kibana/vizualization.json /vizualization.json
  cp -f /elk-content/elk-content/kibana/dashboard.json /dashboard.json
  sed "s,elk_ELASTICSEARCH_MASTER_PROJECT_ID,${elk_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /search.json
  sed "s,elk_ELASTICSEARCH_MASTER_PROJECT_ID,${elk_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /vizualization.json
  sed "s,elk_ELASTICSEARCH_MASTER_PROJECT_ID,${elk_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /dashboard.json
  

  curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_cluster/settings" -d '{"transient": { "discovery.zen.minimum_master_nodes": 2 }}'

  curl -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/{{.Values.elk_elasticsearch_master_project_id}}" -d "@/monasca-content/monasca-content/elasticsearch/{{.Values.monasca_elasticsearch_master_project_id}}.json"

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
  
  cat <(crontab -l) <(echo "0 6 * * * /usr/local/bin/curator --config /elk-etc/elk-wall-e-curator.yml  /elk-etc/elk-wall-e-delete_indices.yml > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "* * * * * /usr/bin/python2.7 /elk-bin/elasticsearch-test.py > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -
  cat <(crontab -l) <(echo "0 3 * * * . /elk-bin/create-kibana-audit-indexes.sh  > ${STDOUT_LOC} 2> ${STDERR_LOC}") | crontab -

  exec cron -f 

}

process_config

start_application
