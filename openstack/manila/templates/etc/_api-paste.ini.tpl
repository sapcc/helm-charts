#############
# OpenStack #
#############

[composite:osapi_share]
use = call:manila.api:root_app_factory
/: apiversions
{{- if .Values.api_v1_enabled }}
/v1: openstack_share_api
{{- end }}
/v2: openstack_share_api_v2

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "rate_limit_pipe" -}}
{{- if .Values.api_rate_limit.enabled }} rate_limit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

[composite:openstack_share_api]
use = call:manila.api.middleware.auth:pipeline_factory
noauth = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit noauth {{- include "watcher_pipe" . }} api
keystone = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "rate_limit_pipe" . }} {{- include "audit_pipe" . }} api
keystone_nolimit = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} api

[composite:openstack_share_api_v2]
use = call:manila.api.middleware.auth:pipeline_factory
noauth = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit noauth {{- include "watcher_pipe" . }} apiv2
keystone = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "rate_limit_pipe" . }} {{- include "audit_pipe" . }} apiv2
keystone_nolimit = cors {{- include "osprofiler_pipe" . }} faultwrap http_proxy_to_wsgi sizelimit authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv2

[filter:faultwrap]
paste.filter_factory = manila.api.middleware.fault:FaultWrapper.factory

[filter:noauth]
paste.filter_factory = manila.api.middleware.auth:NoAuthMiddleware.factory

[filter:sizelimit]
paste.filter_factory = oslo_middleware.sizelimit:RequestBodySizeLimiter.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

[app:api]
paste.app_factory = manila.api.v1.router:APIRouter.factory

[app:apiv2]
paste.app_factory = manila.api.v2.router:APIRouter.factory

[pipeline:apiversions]
pipeline = cors healthcheck faultwrap http_proxy_to_wsgi osshareversionapp

[app:osshareversionapp]
paste.app_factory = manila.api.versions:VersionsRouter.factory

##########
# Shared #
##########

[filter:keystonecontext]
paste.filter_factory = manila.api.middleware.auth:ManilaKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = manila

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/manila/healthcheck_disable

{{ if .Values.audit.enabled -}}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/manila/manila_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.watcher.enabled }}
# openstack-watcher-middleware
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = share
config_file = /etc/manila/watcher.yaml
{{- end }}

{{ if .Values.api_rate_limit.enabled }}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/manila/ratelimit.yaml
service_type = share
rate_limit_by = {{ .Values.api_rate_limit.rate_limit_by }}
max_sleep_time_seconds = {{ .Values.api_rate_limit.max_sleep_time_seconds }}
clock_accuracy = 1ns
log_sleep_time_seconds = {{ .Values.api_rate_limit.log_sleep_time_seconds }}
backend_host = {{ .Release.Name }}-api-ratelimit-redis
backend_port = 6379
backend_secret_file = {{ .Values.api_rate_limit.backend_secret_file }}
backend_timeout_seconds = {{ .Values.api_rate_limit.backend_timeout_seconds }}
{{- end }}

