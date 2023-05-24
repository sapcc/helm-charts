[DEFAULT]
debug = {{ .Values.debug }}
prometheus = true

[api_settings]
policy_file = /etc/archer/policy.json
policy_engine = goslo
auth_strategy = keystone
rate_limit = 100
enable_proxy_headers_parsing = true

[database]
connection = postgresql://postgres:{{ required ".Values.postgresql.postgresPassword variable missing" .Values.postgresql.postgresPassword | urlquery }}@archer-postgresql:5432/archer?sslmode=disable

[service_auth]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Release.Name }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.archer_service_password }}
project_name = service
project_domain_id = default
user_domain_id = default
allow_reauth = true

[quota]
enabled = true
service = 0
endpoint = 0