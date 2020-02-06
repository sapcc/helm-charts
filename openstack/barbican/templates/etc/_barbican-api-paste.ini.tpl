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

# Use this pipeline for Barbican API - versions no authentication
[pipeline:barbican_version]
pipeline = cors healthcheck versionapp

# Use this pipeline for Barbican API - DEFAULT no authentication
[pipeline:barbican_api]
pipeline = cors unauthenticated-context {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiapp

#Use this pipeline to activate a repoze.profile middleware and HTTP port,
#  to provide profiling information for the REST API processing.
[pipeline:barbican-profile]
pipeline = cors unauthenticated-context egg:Paste#cgitb egg:Paste#httpexceptions profile {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiapp

#Use this pipeline for keystone auth
[pipeline:barbican-api-keystone]
pipeline = cors keystone_authtoken context {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiapp

#Use this pipeline for keystone auth with audit feature
[pipeline:barbican-api-keystone-audit]
pipeline = keystone_authtoken context {{- include "watcher_pipe" . }} {{- include "audit_pipe" . }} apiapp

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

[filter:audit]
paste.filter_factory = keystonemiddleware.audit:filter_factory
audit_map_file = /etc/barbican/api_audit_map.conf

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
audit_map_file = /etc/barbican_audit_map.yaml
ignore_req_list = GET
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- end }} 