[composite:main]
use = egg:Paste#urlmap
/: barbican_version
/v1: barbican-api-keystone

{{- define "watcher_pipe" -}}
{{- if .Values.watcher.enabled }} watcher{{- end -}}
{{- end }}

{{- define "audit_pipe" -}}
{{- if .Values.audit.enabled }} audit{{- end -}}
{{- end }}

{{- define "rate_limit_pipe" -}}
{{- if .Values.sapcc_rate_limit.enabled }} rate_limit {{- end -}}
{{- end }}

# Use this pipeline for Barbican API - versions no authentication
[pipeline:barbican_version]
pipeline = cors healthcheck microversion versionapp

# Use this pipeline for Barbican API - DEFAULT no authentication
[pipeline:barbican_api]
pipeline = cors unauthenticated-context {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }}  microversion apiapp

#Use this pipeline to activate a repoze.profile middleware and HTTP port,
#  to provide profiling information for the REST API processing.
[pipeline:barbican-profile]
pipeline = cors unauthenticated-context microversion egg:Paste#cgitb egg:Paste#httpexceptions profile {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }}  apiapp

#Use this pipeline for keystone auth
[pipeline:barbican-api-keystone]
pipeline = cors keystone_authtoken microversion context {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }}  apiapp

#Use this pipeline for keystone auth with audit feature
[pipeline:barbican-api-keystone-audit]
pipeline = keystone_authtoken context microversion {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} {{- include "rate_limit_pipe" . }}  apiapp

[app:apiapp]
paste.app_factory = barbican.api.app:create_main_app

[app:versionapp]
paste.app_factory = barbican.api.app:create_version_app

[filter:simple]
paste.filter_factory = barbican.api.middleware.simple:SimpleFilter.factory

[filter:unauthenticated-context]
paste.filter_factory = barbican.api.middleware.context:UnauthenticatedContextMiddleware.factory

[filter:context]
paste.filter_factory = barbican.api.middleware.context:ContextMiddleware.factory

[filter:healthcheck]
paste.filter_factory = oslo_middleware:Healthcheck.factory
backends = disable_by_file
disable_by_file_path = /etc/barbican/healthcheck_disable

[filter:keystone_authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory

[filter:profile]
use = egg:repoze.profile
log_filename = myapp.profile
cachegrind_filename = cachegrind.out.myapp
discard_first_request = true
path = /__profile__
flush_at_shutdown = true
unwind = false

[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = barbican

{{ if .Values.watcher.enabled -}}
[filter:watcher]
use = egg:watcher-middleware#watcher
service_type = key-manager
config_file = /etc/barbican/watcher.yaml
{{- end }}

{{ if .Values.audit.enabled -}}
[filter:audit]
paste.filter_factory = auditmiddleware:filter_factory
audit_map_file = /etc/barbican/barbican_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }}

{{ if .Values.sapcc_rate_limit.enabled -}}
[filter:rate_limit]
use = egg:rate-limit-middleware#rate-limit
config_file = /etc/barbican/ratelimit.yaml
service_type = key-manager
rate_limit_by = initiator_project_id
max_sleep_time_seconds = 20
clock_accuracy = 1ns
log_sleep_time_seconds = 10
backend_host = {{ .Release.Name }}-sapcc-rate-limit
backend_port = 6379
backend_timeout_seconds = 1
{{- end }}
