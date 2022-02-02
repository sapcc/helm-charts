#!/bin/sh

export STDOUT_LOC=${STDOUT_LOC:-/proc/1/fd/1}  
export STDERR_LOC=${STDERR_LOC:-/proc/1/fd/2}
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

echo "setting kibana csv separator"
curl -XPOST -H "kbn-xsrf: 1" -H "content-type: application/JSON" -u {{.Values.global.elastiflow_admin_user}}:{{.Values.global.elastiflow_admin_password}} "http://{{ template "kibana.fullname" . }}:{{.Values.service.port}}/api/kibana/settings"  -d '{"changes": {"csv:separator": ";"}}'
