[DEFAULT]
{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[pipeline:main]
pipeline = catch_errors proxy-logging cache symlink proxy-server

[app:proxy-server]
use = egg:swift#proxy
# container sharder requires account autocreate
account_autocreate = true

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{.Release.Namespace}}.svc:11211

[filter:symlink]
use = egg:swift#symlink
