[composite:osapi_dns]
use = egg:Paste#urlmap
/: osapi_dns_versions
/healthcheck: healthcheck
/v2: osapi_dns_v2
/admin: osapi_dns_admin

[composite:osapi_dns_versions]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors maintenance faultwrapper sentry {{- include "osprofiler_pipe" . }} osapi_dns_app_versions
keystone = http_proxy_to_wsgi cors maintenance faultwrapper sentry {{- include "osprofiler_pipe" . }} osapi_dns_app_versions

[app:osapi_dns_app_versions]
paste.app_factory = designate.api.versions:factory

[composite:osapi_dns_v2]
{{- define "rate_limit_pipe" -}}
{{- if .Values.rate_limit.enabled }} rate_limit{{- end -}}
{{- end }}
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id faultwrapper sentry validation_API_v2 {{- include "osprofiler_pipe" . }} noauthcontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_v2
keystone = http_proxy_to_wsgi cors request_id faultwrapper sentry validation_API_v2 {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri{{ if .Values.rate_limit.enabled }}{{- include "rate_limit_pipe" . }}{{ end }} {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_v2

[app:healthcheck]
paste.app_factory = oslo_middleware:Healthcheck.app_factory
backends = disable_by_file
disable_by_file_path = /etc/designate/healthcheck_disable

[app:osapi_dns_app_v2]
paste.app_factory = designate.api.v2:factory

[composite:osapi_dns_admin]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id faultwrapper sentry {{- include "osprofiler_pipe" . }} noauthcontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_admin
keystone = http_proxy_to_wsgi cors request_id faultwrapper sentry {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }} osapi_dns_app_admin

[app:osapi_dns_app_admin]
paste.app_factory = designate.api.admin:factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = designate

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:noauthcontext]
paste.filter_factory = designate.api.middleware:NoAuthContextMiddleware.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:keystonecontext]
paste.filter_factory = designate.api.middleware:KeystoneContextMiddleware.factory

[filter:maintenance]
paste.filter_factory = designate.api.middleware:MaintenanceMiddleware.factory

[filter:normalizeuri]
paste.filter_factory = designate.api.middleware:NormalizeURIMiddleware.factory

[filter:faultwrapper]
paste.filter_factory = designate.api.middleware:FaultWrapperMiddleware.factory

[filter:validation_API_v2]
paste.filter_factory = designate.api.middleware:APIv2ValidationErrorMiddleware.factory

[filter:sentry]
use = egg:raven#raven
level = ERROR

# Converged Cloud audit middleware
{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/designate/designate_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = dns
config_file = /etc/designate/watcher.yaml
{{- end }}

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

{{ if .Values.rate_limit.enabled -}}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/designate/ratelimit.yaml
service_type = dns
rate_limit_by = {{ .Values.rate_limit.rate_limit_by }}
max_sleep_time_seconds: {{ .Values.rate_limit.max_sleep_time_seconds }}
clock_accuracy = 1ns
log_sleep_time_seconds: {{ .Values.rate_limit.log_sleep_time_seconds }}
backend_host = {{ .Release.Name }}-api-ratelimit-redis
backend_port = 6379
backend_secret_file = {{ .Values.rate_limit.backend_secret_file }}
backend_timeout_seconds = {{ .Values.rate_limit.backend_timeout_seconds }}
{{- end }}
