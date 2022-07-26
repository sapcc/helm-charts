{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "limes_common_envvars" }}
- name: LIMES_DEBUG
  value: '0'
- name: LIMES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: postgres_password
- name: LIMES_DB_HOSTNAME
  value: "limes-postgresql.{{ .Release.Namespace }}.svc"
- name: LIMES_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: LIMES_COLLECTOR_DATA_METRICS_EXPOSE
  value: "true"
- name: LIMES_COLLECTOR_DATA_METRICS_SKIP_ZERO
  value: "true"
- name: CCLOUD_AUTH_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: ccloud_auth_password
- name: CCLOUD_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: ccloud_rabbitmq_password
{{- end -}}
