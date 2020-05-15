{{- $train := hasPrefix "train" (default .Values.imageVersion .Values.imageVersionServerAPI) -}}
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

{{- define "sentry_pipe" -}}
{{- if .Values.sentry.enabled }} raven{{- end -}}
{{- end }}

[composite:neutronapi_v2_0]
use = call:neutron.auth:pipeline_factory
noauth = cors healthcheck http_proxy_to_wsgi request_id  {{- include "watcher_pipe" . }} catch_errors {{- include "osprofiler_pipe" . }} {{- include "sentry_pipe" . }} extensions neutronapiapp_v2_0
keystone = cors healthcheck http_proxy_to_wsgi request_id catch_errors {{- include "osprofiler_pipe" . }} {{- include "sentry_pipe" . }} authtoken keystonecontext {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} extensions neutronapiapp_v2_0

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
{{- if $train }}
paste.app_factory = neutron.pecan_wsgi.app:versions_factory
{{- else }}
paste.app_factory = neutron.api.versions:Versions.factory
{{ end }}

[app:neutronapiapp_v2_0]
paste.app_factory = neutron.api.v2.router:APIRouter.factory

[pipeline:neutronversions]
pipeline = http_proxy_to_wsgi healthcheck neutronversionsapp

[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory

{{- if .Values.sentry.enabled }}
[filter:raven]
use = egg:raven#raven
level = ERROR
{{- end }}

{{ if .Values.audit.enabled }}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/neutron/neutron_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.watcher.enabled }}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = network
config_file = /etc/neutron/watcher.yaml
{{- end }}
