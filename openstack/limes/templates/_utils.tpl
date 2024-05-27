{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "limes_common_envvars" }}
{{- if $.Values.limes.has_audit_trail }}
- name: LIMES_AUDIT_ENABLE
  value: "true"
- name: LIMES_AUDIT_QUEUE_NAME
  value: "notifications.info"
- name: LIMES_AUDIT_RABBITMQ_HOSTNAME
  value: "hermes-rabbitmq-notifications.hermes.svc"
- name: LIMES_AUDIT_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: rabbitmq_password
- name: LIMES_AUDIT_RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: rabbitmq_username
{{- end }}
- name: LIMES_AUTHORITATIVE
  value: "true"
- name: LIMES_CONSTRAINTS_PATH
  value: "/etc/limes/constraints-ccloud.yaml"
- name: LIMES_DEBUG
  value: '0'
- name: LIMES_DB_USERNAME
  value: 'limes'
- name: LIMES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-limes'
      key: 'postgres-password'
- name: LIMES_DB_HOSTNAME
  value: "limes-postgresql.{{ .Release.Namespace }}.svc"
- name: LIMES_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: LIMES_COLLECTOR_DATA_METRICS_EXPOSE
  value: "true"
- name: LIMES_COLLECTOR_DATA_METRICS_SKIP_ZERO
  value: "true"
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name: OS_INTERFACE
  value: "internal"
- name: OS_USER_DOMAIN_NAME
  value: "Default"
- name: OS_USERNAME
  value: "limes"
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: os_password
- name: OS_PROJECT_DOMAIN_NAME
  value: "ccadmin"
- name: OS_PROJECT_NAME
  value: "cloud_admin"
- name: OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
{{- end -}}
