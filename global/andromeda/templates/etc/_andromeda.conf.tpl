[DEFAULT]
# api_base_uri = http://localhost:8000
transport_url = nats://andromeda-nats:4222

[database]
{{- if not .Values.postgresql.enabled }}
connection = cockroachdb://root@{{ include "andromeda.name" . }}-cockroachdb:26257/andromeda?sslmode=disable
{{- else }}
connection = postgresql://postgres:{{ default "" .Values.postgresql.postgresPassword | urlquery }}@andromeda-postgresql:5432/andromeda?sslmode=disable
{{- end }}

[api_settings]
auth_strategy = none
policy_engine = noop
disable_pagination = false
disable_sorting = false
disable_cors = false
pagination_max_limit = 100
rate_limit = 10
