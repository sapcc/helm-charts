DEFAULT:
  #api_base_uri: http://localhost:8000
  transport_url: nats://andromeda-nats:4222

database:
{{- if .Values.mariadb.enabled }}
  connection: mysql://andromeda:{{ required ".Values.mariadb.users.andromeda.password variable missing" .Values.mariadb.users.andromeda.password | urlquery }}@{{ include "mariadb.db_host" . }}/andromeda?sql_mode=%27ANSI_QUOTES%27
{{- else if .Values.postgresql.enabled }}
  connection: postgresql://postgres:{{ required ".Values.postgresql.postgresPassword variable missing" .Values.postgresql.postgresPassword | urlquery }}@andromeda-postgresql:5432/andromeda?sslmode=disable
{{- end }}

api_settings:
  auth_strategy: keystone
  policy_engine: goslo
  policy-file: /etc/andromeda/policy.json
  pagination_max_limit: 100
  rate_limit: 10
  disable_pagination: false
  disable_sorting: false
  disable_cors: false

service_auth:
  auth_url: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "andromeda_keystone_api_endpoint_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
  username: {{ .Release.Name }}{{ .Values.global.user_suffix }}
  password: {{ .Values.global.andromeda_service_password }}
  project_name: service
  project_domain_id: default
  user_domain_id: default
  allow_reauth: true

quota:
  enabled: true
