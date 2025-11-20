DEFAULT:
  #api_base_uri: http://localhost:8000
  transport_url: nats://andromeda-nats:4222
  prometheus: true
  prometheus_listen: 0.0.0.0:9090

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
{{- else }}
  auth_url: {{ .Values.global.keystone_api_endpoint_protocol_public | default "https"}}://{{include "keystone_api_endpoint_host_public" .}}/v3
{{- end }}
  username: {{ .Release.Name }}{{ .Values.global.user_suffix }}
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

{{- if .Values.audit.enabled }}
audit_middleware_notifications:
  enabled: true
  queue_name: {{.Values.audit.queue_name}}
{{- end }}

house_keeping:
  enabled: true

{{- if .Values.f5.enabled }}
f5_datacenters: {{- .Values.f5_datacenters | toYaml | nindent 2 }}
{{- end }}