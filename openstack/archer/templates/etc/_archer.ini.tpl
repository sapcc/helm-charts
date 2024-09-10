[DEFAULT]
debug = {{ .Values.debug }}
prometheus = true
prometheus_listen = 0.0.0.0:{{ required ".Values.metrics.port missing" .Values.metrics.port }}
sentry = true
endpoint_type = internal

[api_settings]
policy_file = /etc/archer/policy.json
policy_engine = goslo
auth_strategy = keystone
rate_limit = 100
enable_proxy_headers_parsing = true

[database]
connection = postgresql://archer@archer-postgresql:5432/archer?sslmode=disable

[service_auth]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Release.Name }}{{ .Values.global.user_suffix }}
project_name = service
project_domain_id = default
user_domain_id = default
allow_reauth = true

[quota]
enabled = true
service = 0
endpoint = 0

{{- if .Values.audit.enabled }}
[audit_middleware_notifications]
enabled = true
queue_name = notifications.info
{{- end }}