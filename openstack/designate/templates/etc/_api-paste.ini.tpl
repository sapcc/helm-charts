[composite:osapi_dns]
use = egg:Paste#urlmap
/: osapi_dns_versions
/v2: osapi_dns_v2
/admin: osapi_dns_admin

[composite:osapi_dns_versions]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors maintenance faultwrapper sentry osapi_dns_app_versions
keystone = http_proxy_to_wsgi cors maintenance faultwrapper sentry osapi_dns_app_versions

[app:osapi_dns_app_versions]
paste.app_factory = designate.api.versions:factory

[composite:osapi_dns_v2]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id faultwrapper sentry validation_API_v2 noauthcontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_v2
keystone = http_proxy_to_wsgi cors request_id faultwrapper sentry validation_API_v2 authtoken keystonecontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_v2

[app:osapi_dns_app_v2]
paste.app_factory = designate.api.v2:factory

[composite:osapi_dns_admin]
use = call:designate.api.middleware:auth_pipeline_factory
noauth = http_proxy_to_wsgi cors request_id faultwrapper sentry noauthcontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }}osapi_dns_app_admin
keystone = http_proxy_to_wsgi cors request_id faultwrapper sentry authtoken keystonecontext {{ if .Values.watcher.enabled }}watcher {{ end }}maintenance normalizeuri {{ if .Values.audit.enabled }}audit {{ end }} osapi_dns_app_admin

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
