DEFAULT:
  #api_base_uri: http://localhost:8000
  transport_url: nats://andromeda-nats:4222

database:
{{- if not .Values.postgresql.enabled }}
  connection: cockroachdb://root@{{ include "andromeda.name" . }}-cockroachdb:26257/andromeda?sslmode=disable
{{- else }}
  connection: postgresql://postgres:{{ default "" .Values.postgresql.postgresPassword | urlquery }}@andromeda-postgresql:5432/andromeda?sslmode=disable
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