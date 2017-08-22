#!/bin/bash

KIBANA_VERSION="5.4.2"

unset http_proxy

# ccadmin@master alias index
# this is only required for regions with logs in the master project (for example from swift outside of ccloud etc.)
if [ -f /elk-content/elk-content/elasticsearch/{{.Values.cluster_region}}/{{.Values.elk_elasticsearch_master_project_id}}.json ]; then
  curl -s -u {{ .Values.elk_elasticsearch_admin_user }}:{{ .Values.elk_elasticsearch_admin_password }} -XPUT http://{{ .Values.elk_elasticsearch_endpoint_host_internal }}:{{ .Values.elk_elasticsearch_port_internal}}/.kibana/index-pattern/master@ccadmin -d '{"title" : "master@ccadmin",  "timeFieldName": "@timestamp"}'
  # line break for cleaner output
  echo ""
fi

# log indexes
indexes=`curl -s -u {{ .Values.elk_elasticsearch_admin_user }}:{{ .Values.elk_elasticsearch_admin_password }} 'http://{{ .Values.elk_elasticsearch_endpoint_host_internal }}:{{ .Values.elk_elasticsearch_port_internal }}/_cat/indices?v'|awk '{ print $3}'|grep -v audit|awk -F- '{ print $1}'|sort|uniq|grep -v "kibana"|grep -v "index"`

for i in ${indexes}; do
  # this is required to give proper microsecond timings for logstash entries
  if [ "$i" = "logstash" ]; then
    TIME_FIELD_NAME="time"
  else
    TIME_FIELD_NAME="@timestamp"
  fi
  curl -s -u {{ .Values.elk_elasticsearch_admin_user }}:{{ .Values.elk_elasticsearch_admin_password }} -XPUT http://{{ .Values.elk_elasticsearch_endpoint_host_internal }}:{{ .Values.elk_elasticsearch_port_internal}}/.kibana/index-pattern/${i}-* -d "{\"title\" : \"${i}-*\",  \"timeFieldName\": \"$TIME_FIELD_NAME\"}"
  # line break for cleaner output
  echo ""
done

# make the logstash index the default one
curl -s -u {{ .Values.elk_elasticsearch_admin_user }}:{{ .Values.elk_elasticsearch_admin_password }} -XPUT http://{{ .Values.elk_elasticsearch_endpoint_host_internal }}:{{ .Values.elk_elasticsearch_port_internal}}/.kibana/config/$KIBANA_VERSION -d '{"defaultIndex" : "logstash-*"}'
# line break for cleaner output
echo ""
