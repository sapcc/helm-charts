#!/bin/bash

KIBANA_VERSION="5.2.0"

unset http_proxy

# audit indexes
audit_indexes=`curl -s '{{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/_cat/indices?v'|grep audit|awk '{ print $3}'|awk -F- '{ print $2}'|sort |uniq`

for i in ${audit_indexes}; do
  curl -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/index-pattern/audit-${i}-* -d '{"title" : "audit-${i}-*",  "timeFieldName": "@timestamp"}'
done

# create the audit-* index and make it the default one
curl -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/index-pattern/audit-* -d '{"title" : "audit-*",  "timeFieldName": "@timestamp"}'
curl -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/config/$KIBANA_VERSION -d '{"defaultIndex" : "audit-*"}'
