[DEFAULT]
{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[object-expirer]
concurrency = {{ .Values.object_expirer_concurrency }}
tasks_per_second = {{ .Values.object_expirer_tasks_per_second }}

[pipeline:main]
pipeline = catch_errors cache proxy-server

[app:proxy-server]
use = egg:swift#proxy

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{.Release.Namespace}}.svc:11211
memcache_max_connections = 32

[filter:catch_errors]
use = egg:swift#catch_errors
