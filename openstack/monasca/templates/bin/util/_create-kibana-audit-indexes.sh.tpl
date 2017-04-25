#!/bin/bash

unset http_proxy


# audit indexes
#############
audit_indexes=`curl -s -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} 'http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal }}/_cat/indices?v'|grep audit|awk '{ print $3}'|awk -F- '{ print $2}'|sort |uniq`

for e in ${audit_indexes}
do
  curl -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} -XPUT http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal}}/.kibana/index-pattern/audit-${e}-* -d '{"title" : "audit-${e}-*",  "timeFieldName": "@timestamp"}'
done

#alias index
############
 curl -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} -XPUT http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal}}/.kibana/index-pattern/master@ccadmin -d '{"title" : "master@ccadmin",  "timeFieldName": "@timestamp"}' }} }} }} }}

# log indexes
##############
indexes=`curl -s -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} 'http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal }}/_cat/indices?v'|awk '{ print $3}'|grep -v audit|awk -F- '{ print $1}'|sort|uniq|grep -v "kibana"|grep -v "index"`

for i in ${indexes}
do
  curl -u {{ .Values.monasca_elasticsearch_admin_user }}:{{ .Values.monasca_elasticsearch_admin_password }} -XPUT http://{{ .Values.monasca_elasticsearch_endpoint_host_internal }}:{{ .Values.monasca_elasticsearch_port_internal}}/.kibana/index-pattern/audit-${i}-* -d '{"title" : "audit-${i}-*",  "timeFieldName": "@timestamp"}'
done
