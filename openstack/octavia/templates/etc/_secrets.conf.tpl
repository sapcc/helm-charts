[DEFAULT]
# AMQP Transport URL
{{ include "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Release.Name }}
password = {{ .Values.global.octavia_service_password | replace "$" "" }}

[database]
connection = {{ include "db_url_mysql" . }}

[f5_agent]
bigip_urls = {{ if $loadbalancer.devices -}}{{- tuple $envAll $loadbalancer.devices | include "utils.bigip_urls" -}}{{- else -}}{{ $loadbalancer.bigip_urls | join ", " }}{{- end }}

{{ if .Values.audit.enabled -}}
[audit]
enabled = True
audit_map_file = /etc/octavia/octavia_api_audit_map.yaml
ignore_req_list = GET, HEAD
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}
{{- include "ini_sections.audit_middleware_notifications" . }}
{{- end }}
