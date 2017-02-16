{{- define "container-sync-realms.conf" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
[DEFAULT]
mtime_check_interval = 300

[self_sync]
# TODO Do we need the self sync still
key = {{$cluster.selfsync_key}}
key2 = {{$cluster.selfsync_key}}
cluster_{{$context.global.region}}-1 = https://{{- tuple $cluster $context | include "swift_endpoint_host" }}/v1
cluster_{{$context.global.region}}-2 = https://{{- tuple $cluster $context | include "swift_endpoint_host" }}/v1
{{end}}
