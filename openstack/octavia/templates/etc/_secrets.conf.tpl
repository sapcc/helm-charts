[DEFAULT]
# AMQP Transport URL
{{ include "ini_sections.default_transport_url" . }}
{{- $name := required "No defaultUser defined in service_users" .Values.service_users.defaultUser }}
{{- $creds := required (printf "No user '%s' in service_users.users" $name) (index .Values.service_users.users $name) }}

[service_auth]
username = {{ $creds.username | include "resolve_secret" }}
password = {{ $creds.password | include "resolve_secret" }}

[keystone_authtoken]
username = {{ $creds.username | include "resolve_secret" }}
password = {{ $creds.password | include "resolve_secret" }}

[database]
connection = {{ include "utils.db_url" . }}

{{ if .Values.audit.enabled -}}
[audit]
enabled = True
audit_map_file = /etc/octavia/octavia_api_audit_map.yaml
ignore_req_list = GET, HEAD
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- include "ini_sections.audit_middleware_notifications" . }}
{{- end }}

{{- if .Values.osprofiler.enabled }}
# Tracing
{{- include "osprofiler" . }}
{{- end }}
