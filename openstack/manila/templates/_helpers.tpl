{{- define "manila_type_seed.specs" }}
driver_handles_share_servers: true
snapshot_support: true
{{- end }}

{{/*
Define the Manila API dependency services for kubernetes-entrypoint init container
memcached is being used only by API via keystoneauth
*/}}
{{- define "manila.api_service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }},{{ template "manila.memcached_service" . }}
{{- end }}

{{/*
Define the Manila dependency services for kubernetes-entrypoint init container
*/}}
{{- define "manila.service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }}
{{- end }}

{{- define "manila.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "manila.rabbitmq_service" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}

{{- define "manila.memcached_service" }}
  {{- .Release.Name }}-memcached
{{- end }}
