#!/bin/bash

KIBANA_VERSION="6.6.1"

unset http_proxy

# audit indexes - the grep -v payload is to get rid of the broken audit-%{[payload][project]}-* index
audit_indexes=`curl -H \'Content-Type: application/json\' -s '{{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/_cat/indices?v' | grep audit | awk '{ print $3}'|awk -F- '{ print $2}' | sort |uniq | grep -v payload`

for i in ${audit_indexes}; do
  curl -H 'Content-Type: application/json' -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/index-pattern/audit-${i}-* -d '{"title" : "audit-${i}-*",  "timeFieldName": "@timestamp"}'
  # line break for cleaner output
  echo ""
done

# create the audit-* index and make it the default one
curl -H 'Content-Type: application/json' -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/index-pattern/audit-* -d '{"title" : "audit-*",  "timeFieldName": "@timestamp"}'
# line break for cleaner output
echo ""
curl -H 'Content-Type: application/json' -s -XPUT {{ .Values.hermes_elasticsearch_protocol }}://{{ .Values.hermes_elasticsearch_host }}:{{ .Values.hermes_elasticsearch_port }}/.kibana/config/$KIBANA_VERSION -d '{"defaultIndex" : "audit-*"}'
# line break for cleaner output
echo ""
