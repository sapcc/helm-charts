{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end -}}

{{- define "rate_limit_pipe" -}}
{{- if .Values.rate_limit.enabled }} rate_limit{{- end -}}
{{- end }}

############
# Metadata #
############
[composite:metadata]
use = egg:Paste#urlmap
/: meta
# provides an endpoint for healthcheck enabling us to disable the service
/healthcheck: healthcheck

[pipeline:meta]
pipeline = cors {{- include "osprofiler_pipe" . }} {{- include "watcher_pipe" . }} sentry metaapp

[app:metaapp]
paste.app_factory = nova.api.metadata.handler:MetadataRequestHandler.factory

#############
# OpenStack #
#############

[composite:osapi_compute]
use = call:nova.api.openstack.urlmap:urlmap_factory
/: oscomputeversions
/v2: oscomputeversion_legacy_v2
/v2.1: oscomputeversion_v2
# v21 is an exactly feature match for v2, except it has more stringent
# input validation on the wsgi surface (prevents fuzzing early on the
# API). It also provides new features via API microversions which are
# opt into for clients. Unaware clients will receive the same frozen
# v2 API feature set, but with some relaxed validation
/v2/+: openstack_compute_api_v21_legacy_v2_compatible
/v2.1/+: openstack_compute_api_v21
# provides an endpoint for healthcheck enabling us to disable the service
/healthcheck: healthcheck

[composite:openstack_compute_api_v21]
use = call:nova.api.auth:pipeline_factory_v21
keystone = cors http_proxy_to_wsgi compute_req_id faultwrap request_log sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "rate_limit_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21

[composite:openstack_compute_api_v21_legacy_v2_compatible]
use = call:nova.api.auth:pipeline_factory_v21
keystone = cors http_proxy_to_wsgi compute_req_id faultwrap request_log sizelimit {{- include "osprofiler_pipe" . }} authtoken keystonecontext legacy_v2_compatible {{- include "watcher_pipe" . }} sentry {{- include "audit_pipe" . }} osapi_compute_app_v21

[filter:request_log]
paste.filter_factory = nova.api.openstack.requestlog:RequestLog.factory

[filter:compute_req_id]
paste.filter_factory = nova.api.compute_req_id:ComputeReqIdMiddleware.factory

[filter:faultwrap]
paste.filter_factory = nova.api.openstack:FaultWrapper.factory

[filter:osprofiler]
paste.filter_factory = nova.profiler:WsgiMiddleware.factory

[filter:sizelimit]
paste.filter_factory = oslo_middleware:RequestBodySizeLimiter.factory

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware.http_proxy_to_wsgi:HTTPProxyToWSGI.factory

[filter:legacy_v2_compatible]
paste.filter_factory = nova.api.openstack:LegacyV2CompatibleWrapper.factory

[app:osapi_compute_app_v21]
paste.app_factory = nova.api.openstack.compute:APIRouterV21.factory

[pipeline:oscomputeversions]
pipeline = cors faultwrap request_log http_proxy_to_wsgi oscomputeversionapp

[app:oscomputeversionapp]
paste.app_factory = nova.api.openstack.compute.versions:Versions.factory

[pipeline:oscomputeversion_v2]
pipeline = cors compute_req_id faultwrap request_log http_proxy_to_wsgi oscomputeversionapp_v2

[pipeline:oscomputeversion_legacy_v2]
pipeline = cors compute_req_id faultwrap request_log http_proxy_to_wsgi legacy_v2_compatible oscomputeversionapp_v2

[app:oscomputeversionapp_v2]
paste.app_factory = nova.api.openstack.compute.versions:VersionsV2.factory

##########
# Shared #
##########

[app:healthcheck]
paste.app_factory = oslo_middleware:Healthcheck.app_factory
backends = disable_by_file
disable_by_file_path = /etc/nova/healthcheck_disable

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = nova

[filter:keystonecontext]
paste.filter_factory = nova.api.auth:NovaKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:sentry]
use = egg:raven#raven
level = ERROR

{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/nova/nova_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{- if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = compute
config_file = /etc/nova/watcher.yaml
{{- end }}

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
backend_timeout_seconds = {{ .Values.rate_limit.backend_timeout_seconds }}
{{- end }}
