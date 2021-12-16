{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "limes_common_envvars" }}
- name: LIMES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: postgres_password
- name: LIMES_DB_HOSTNAME
  value: "limes-postgresql.{{ .Release.Namespace }}.svc"
- name: LIMES_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: LIMES_API_REQUEST_LOG_EXCEPT_STATUS_CODES
  value: "300"
- name: LIMES_API_CORS_ALLOWED_ORIGINS
  {{- if .Values.limes.relaxed_cors }}
  value: "*"
  {{- else }}
  value: "https://dashboard.{{.Values.global.region}}.{{.Values.global.tld}}"
  {{- end }}
- name: LIMES_COLLECTOR_DATA_METRICS_EXPOSE
  value: "true"
- name: LIMES_COLLECTOR_DATA_METRICS_SKIP_ZERO
  value: "true"
{{- range $cluster_id, $cfg := .Values.limes.clusters }}
- name: {{ $cluster_id | upper }}_AUTH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: {{ $cluster_id }}_auth_password
- name: {{ $cluster_id | upper }}_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: {{ $cluster_id }}_rabbitmq_password
{{- end }}
- name: LIMES_DEBUG
  value: '0'
- name: LIMES_DEBUG_SQL
  value: '0'
{{- end -}}
