# Use this pipeline for no auth or image caching - DEFAULT
[pipeline:glance-api]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} rootapp

# Use this pipeline for image caching and no auth
[pipeline:glance-api-caching]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} cache rootapp

# Use this pipeline for caching w/ management interface but no auth
[pipeline:glance-api-cachemanagement]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler unauthenticated-context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} cache cachemanage rootapp

# Use this pipeline for keystone auth
[pipeline:glance-api-keystone]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} rootapp

# Use this pipeline for keystone auth with image caching
[pipeline:glance-api-keystone+caching]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} cache rootapp

# Use this pipeline for keystone auth with caching and cache management
[pipeline:glance-api-keystone+cachemanagement]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler authtoken context {{ if .Values.watcher.enabled }}watcher{{ end }} {{ if .Values.sapcc_rate_limit.enabled }}rate_limit{{ end }} {{ if .Values.audit.enabled }}audit{{ end }} cache cachemanage rootapp

# Use this pipeline for authZ only. This means that the registry will treat a
# user as authenticated without making requests to keystone to reauthenticate
# the user.
[pipeline:glance-api-trusted-auth]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler context rootapp

# Use this pipeline for authZ only. This means that the registry will treat a
# user as authenticated without making requests to keystone to reauthenticate
# the user and uses cache management
[pipeline:glance-api-trusted-auth+cachemanagement]
pipeline = cors healthcheck http_proxy_to_wsgi versionnegotiation osprofiler context cache cachemanage rootapp

[pipeline:apiversions]
pipeline = http_proxy_to_wsgi apiversionsapp

[composite:rootapp]
paste.composite_factory = glance.api:root_app_factory
/: apiversions
/v1: apiv1app
/v2: apiv2app

[app:apiversionsapp]
paste.app_factory = glance.api.versions:create_resource

[app:apiv1app]
paste.app_factory = glance.api.v1.router:API.factory

[app:apiv2app]
paste.app_factory = glance.api.v2.router:API.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/glance/healthcheck_disable

[filter:versionnegotiation]
paste.filter_factory = glance.api.middleware.version_negotiation:VersionNegotiationFilter.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:cache]
paste.filter_factory = glance.api.middleware.cache:CacheFilter.factory

[filter:cachemanage]
paste.filter_factory = glance.api.middleware.cache_manage:CacheManageFilter.factory

[filter:context]
paste.filter_factory = glance.api.middleware.context:ContextMiddleware.factory

[filter:unauthenticated-context]
paste.filter_factory = glance.api.middleware.context:UnauthenticatedContextMiddleware.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
delay_auth_decision = true

[filter:gzip]
paste.filter_factory = glance.api.middleware.gzip:GzipMiddleware.factory

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:cors]
paste.filter_factory =  oslo_middleware.cors:filter_factory
oslo_config_project = glance
oslo_config_program = glance-api

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = image
config_file = /etc/glance/watcher.yaml
{{- end }}

# Converged Cloud audit middleware
{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/glance/glance_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.sapcc_rate_limit.enabled -}}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/glance/ratelimit.yaml
service_type = image
rate_limit_by = initiator_project_id
max_sleep_time_seconds = 20
clock_accuracy = 1ns
log_sleep_time_seconds = 10
backend_host = {{ .Release.Name }}-sapcc-rate-limit
backend_port = 6379
backend_timeout_seconds = 1
{{- end }}
