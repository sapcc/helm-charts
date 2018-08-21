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
  cp -f /elk-content/elk-content/kibana/search.json /search.json
  cp -f /elk-content/elk-content/kibana/visualization.json /visualization.json
  cp -f /elk-content/elk-content/kibana/dashboard.json /dashboard.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /search.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /visualization.json
  sed "s,ELK_ELASTICSEARCH_MASTER_PROJECT_ID,${ELK_ELASTICSEARCH_MASTER_PROJECT_ID},g" -i /dashboard.json

  echo "INFO: setting discovery.zen.minimum_master_nodes to 2"  
  curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_cluster/settings" -d '{"transient": { "discovery.zen.minimum_master_nodes": 2 }}'

  # this is only required for regions with logs in the master project (for example from swift outside of ccloud etc.)
  if [ -f /elk-content/elk-content/elasticsearch/{{.Values.cluster_region}}/{{.Values.elk_elasticsearch_master_project_id}}.json ]; then
    echo "INFO: creating index for master project {{.Values.elk_elasticsearch_master_project_id}}"
    curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/{{.Values.elk_elasticsearch_master_project_id}}" -d "@/elk-content/elk-content/elasticsearch/{{.Values.cluster_region}}/{{.Values.elk_elasticsearch_master_project_id}}.json"
  else
    echo "INFO: no master project id defined in secrets or no config found for it in elk-content - not creating an index for it"
  fi

  echo ""
  echo "INFO: creating index for fluentd/logstash logs"
  curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/logstash" -d "@/wall-e-etc/logstash.json"

  echo ""
  echo "INFO: creating index for fluent-systemd/systemd logs"
  curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/systemd" -d "@/wall-e-etc/systemd.json"

  echo ""
  echo "INFO: creating index for filebeat/jump server logs"
  curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/jump" -d "@/wall-e-etc/jump.json"

  echo ""
  echo "INFO: creating index for fluentd/kubernikus server logs"
  curl -s -u {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}} -XPUT "http://{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/_template/kubernikus" -d "@/wall-e-etc/kubernikus.json"

  echo ""
  echo "INFO: setting up the discover panel"
  /node_modules/elasticdump/bin/elasticdump \
      --input=/search.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data

  echo "INFO: setting up the visualization panel"
  /node_modules/elasticdump/bin/elasticdump \
      --input=/visualization.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data
  
  echo "INFO: setting up the dashboard panel"
  /node_modules/elasticdump/bin/elasticdump \
      --input=/dashboard.json \
      --output=http://{{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}@{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}/.kibana \
      --type=data

  # run the creation of the index patterns and the index retention cleanup deletion once on startup and put them into cron to run once per night afterwards
  echo "INFO: creating the indexes"
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
