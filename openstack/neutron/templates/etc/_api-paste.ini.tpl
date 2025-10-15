[composite:neutron]
use = egg:Paste#urlmap
/: neutronversions
/v2.0: neutronapi_v2_0

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

{{- define "rate_limit_pipe" -}}
{{- if ((.Values.rate_limit).enabled) }} rate_limit {{- end -}}
{{- end }}

{{- define "sentry_pipe" -}}
{{- if .Values.sentry.enabled }} sapccsentry {{- end -}}
{{- end }}

{{- define "uwsgi_pipe" -}}
{{ if .Values.api.uwsgi }} uwsgi manhole{{- end -}}
{{- end }}

[composite:neutronapi_v2_0]
use = call:neutron.auth:pipeline_factory
noauth = cors healthcheck http_proxy_to_wsgi request_id  {{- include "watcher_pipe" . }} catch_errors {{- include "osprofiler_pipe" . }} {{- include "sentry_pipe" . }} {{- include "uwsgi_pipe" . }} extensions neutronapiapp_v2_0
keystone = cors healthcheck http_proxy_to_wsgi request_id catch_errors {{- include "osprofiler_pipe" . }} {{- include "sentry_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "rate_limit_pipe" . }} {{- include "audit_pipe" . }} {{- include "uwsgi_pipe" . }} extensions neutronapiapp_v2_0

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/neutron/healthcheck_disable

[filter:request_id]
paste.filter_factory = oslo_middleware:RequestId.factory

[filter:catch_errors]
paste.filter_factory = oslo_middleware:CatchErrors.factory

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = neutron

[filter:http_proxy_to_wsgi]
paste.filter_factory = oslo_middleware:HTTPProxyToWSGI.factory

[filter:keystonecontext]
paste.filter_factory = neutron.auth:NeutronKeystoneContext.factory

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:extensions]
paste.filter_factory = neutron.api.extensions:plugin_aware_extension_middleware_factory

[app:neutronversionsapp]
paste.app_factory = neutron.pecan_wsgi.app:versions_factory

[app:neutronapiapp_v2_0]
paste.app_factory = neutron.api.v2.router:APIRouter.factory

[pipeline:neutronversions]
pipeline = http_proxy_to_wsgi healthcheck neutronversionsapp

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

[filter:debug]
paste.filter_factory = oslo_middleware:Debug.factory

{{ if .Values.sentry.enabled -}}
[filter:sapccsentry]
paste.filter_factory = sapcc_sentrylogger.paste:sapcc_sentry_filter_factory
{{- end }}

{{ if .Values.audit.enabled -}}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/neutron/neutron_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.watcher.enabled -}}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = network
config_file = /etc/neutron/watcher.yaml
{{- end }}

{{ if ((.Values.rate_limit).enabled) -}}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/neutron/ratelimit.yaml
service_type = network
rate_limit_by = {{ .Values.rate_limit.rate_limit_by }}
max_sleep_time_seconds: {{ .Values.rate_limit.max_sleep_time_seconds }}
clock_accuracy = 1ns
log_sleep_time_seconds: {{ .Values.rate_limit.log_sleep_time_seconds }}
backend_host = {{ .Release.Name }}-api-ratelimit-redis
backend_port = 6379
backend_secret_file =  {{ .Values.rate_limit.backend_secret_file }}
backend_timeout_seconds = {{ .Values.rate_limit.backend_timeout_seconds }}
{{- end }}


{{ if .Values.api.uwsgi -}}
[filter:manhole]
paste.filter_factory = manhole_middleware:Manhole.factory

[filter:uwsgi]
paste.filter_factory = uwsgi_middleware:Uwsgi.factory
{{- end }}
