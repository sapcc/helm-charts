#!/bin/bash

unset http_proxy

indexes=`curl -s -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} 'http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal }}/_cat/indices?v'|grep audit|awk '{ print $3}'|awk -F- '{ print $2}'|sort |uniq`

for i in ${indexes}
do
  curl -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} -XPUT http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal}}/.kibana/index-pattern/audit-${i}-* -d '{"title" : "audit-${i}-*",  "timeFieldName": "@timestamp"}'
done }' }'`
