[DEFAULT]
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}
{{- if .Values.sentry.enabled }}
log_custom_handlers = swift_sentry.sentry_logger
{{- end }}

[object-expirer]
concurrency = {{ .Values.object_expirer_concurrency }}
# auto_create_account_prefix = .

[pipeline:main]
pipeline = catch_errors cache proxy-server

[app:proxy-server]
use = egg:swift#proxy

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{.Release.Namespace}}.svc:11211

[filter:catch_errors]
use = egg:swift#catch_errors
