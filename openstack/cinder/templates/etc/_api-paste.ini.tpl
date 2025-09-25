{{- $mitaka := hasPrefix "mitaka" (default .Values.imageVersion .Values.imageVersionCinderApi) -}}
#############
# OpenStack #
#############

[composite:osapi_volume]
use = call:cinder.api:root_app_factory
/: apiversions
{{- if $mitaka }}
/v1: openstack_volume_api_v1
{{- end }}
/v2: openstack_volume_api_v2
/v3: openstack_volume_api_v3

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

{{- define "rate_limit_pipe" -}}
{{- if .Values.api_rate_limit.enabled }} rate_limit{{- end -}}
{{- end }}

{{- if $mitaka }}
[composite:openstack_volume_api_v1]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id faultwrap sizelimit {{- include "osprofiler_pipe" . }} noauth apiv1
keystone = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv1
keystone_nolimit = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv1
{{ end }}

[composite:openstack_volume_api_v2]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id {{- include "watcher_pipe" . }} faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} {{- include "rate_limit_pipe" . }} noauth apiv2
keystone = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }} apiv2
keystone_nolimit = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} {{- include "rate_limit_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv2

[composite:openstack_volume_api_v3]
use = call:cinder.api.middleware.auth:pipeline_factory
noauth = cors http_proxy_to_wsgi request_id {{- include "watcher_pipe" . }} faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} {{- include "rate_limit_pipe" . }} noauth apiv3
keystone = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }} apiv3
keystone_nolimit = cors http_proxy_to_wsgi request_id faultwrap sentry sizelimit {{- include "osprofiler_pipe" . }} {{- include "rate_limit_pipe" .}} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiv3

[filter:request_id]
paste.filter_factory = oslo_middleware.request_id:RequestId.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = cinder

[filter:faultwrap]
paste.filter_factory = cinder.api.middleware.fault:FaultWrapper.factory

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:noauth]
paste.filter_factory = cinder.api.middleware.auth:NoAuthMiddleware.factory

[filter:sizelimit]
paste.filter_factory =  oslo_middleware.sizelimit:RequestBodySizeLimiter.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/cinder/healthcheck_disable

{{- if $mitaka }}
[app:apiv1]
paste.app_factory = cinder.api.v1.router:APIRouter.factory
{{- end }}

[app:apiv2]
paste.app_factory = cinder.api.v2.router:APIRouter.factory

[app:apiv3]
paste.app_factory = cinder.api.v3.router:APIRouter.factory

[pipeline:apiversions]
pipeline = cors healthcheck http_proxy_to_wsgi faultwrap osvolumeversionapp

[app:osvolumeversionapp]
paste.app_factory = cinder.api.versions:Versions.factory

##########
# Shared #
##########

[filter:keystonecontext]
paste.filter_factory = cinder.api.middleware.auth:CinderKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:sentry]
use = egg:raven#raven
level = ERROR

{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/cinder/cinder_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = volume
config_file = /etc/cinder/watcher.yaml
{{- end }}

{{ if .Values.api_rate_limit.enabled -}}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/cinder/ratelimit.yaml
service_type = volume
rate_limit_by = {{ .Values.api_rate_limit.rate_limit_by }}
max_sleep_time_seconds = {{ .Values.api_rate_limit.max_sleep_time_seconds }}
clock_accuracy = 1ns
log_sleep_time_seconds = {{ .Values.api_rate_limit.log_sleep_time_seconds }}
backend_host = {{ .Release.Name }}-api-ratelimit-redis
backend_port = 6379
backend_secret_file = {{ .Values.api_rate_limit.backend_secret_file }}
backend_timeout_seconds = {{ .Values.api_rate_limit.backend_timeout_seconds }}
{{- end }}
