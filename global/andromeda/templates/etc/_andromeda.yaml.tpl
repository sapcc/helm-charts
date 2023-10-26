DEFAULT:
  #api_base_uri: http://localhost:8000
  transport_url: nats://andromeda-nats:4222

database:
{{- if .Values.database_override.enabled }}
  connection: postgresql://postgres:{{ required ".Values.database_override.password variable missing" .Values.database_override.password | urlquery }}@{{ .Values.database_override.host }}/andromeda?sslmode=disable
{{- else if .Values.mariadb.enabled }}
  connection: mysql://andromeda:{{ required ".Values.mariadb.users.andromeda.password variable missing" .Values.mariadb.users.andromeda.password | urlquery }}@{{.Release.Name}}-mariadb/andromeda?sql_mode=%27ANSI_QUOTES%27
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
{{- if eq .Values.global.region "global" }}
  auth_url: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "andromeda_keystone_global_api_endpoint_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
{{- else if ne .Values.global.clusterType "scaleout" }}
  auth_url: {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "andromeda_keystone_api_endpoint_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
{{- else }}
  auth_url: {{ .Values.global.keystone_api_endpoint_protocol_public | default "https"}}://{{include "keystone_api_endpoint_host_public" .}}/v3
{{- end }}
  username: {{ .Release.Name }}{{ .Values.global.user_suffix }}
  password: {{ .Values.global.andromeda_service_password }}
  project_name: service
  project_domain_id: default
  user_domain_id: default
  allow_reauth: true

quota:
  enabled: true
{{- if .Values.debug }}
  domains: 100
  pools: 100
  members: 100
  monitors: 100
  datacenters: 100
{{- end }}

house_keeping:
  enabled: true