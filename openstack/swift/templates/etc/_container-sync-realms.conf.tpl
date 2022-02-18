{{- define "container-sync-realms.conf" -}}
[DEFAULT]
mtime_check_interval = 300

[self_sync]
# TODO Do we need the self sync still
key = {{- .Values.selfsync_key }}
key2 = {{- .Values.selfsync_key }}
cluster_{{ .Values.global.region }}-1 = https://{{- include "swift_endpoint_host" . }}/v1
cluster_{{ .Values.global.region }}-2 = https://{{- include "swift_endpoint_host" . }}/v1

{{end}}
