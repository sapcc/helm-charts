{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "limes_common_envvars" }}
{{- if $.Values.limes.has_audit_trail }}
- name: LIMES_AUDIT_RABBITMQ_QUEUE_NAME
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
{{ include "limes_openstack_envvars" . }}
{{- end -}}

{{- define "limes_openstack_envvars" }}
{{- $limes_url := .Values.limes.clusters.ccloud.catalog_url }}
{{- if .Values.global.is_global_region }}
- name: OS_AUTH_URL
  value: "{{ $limes_url | replace "limes" "identity" }}/v3"
- name: OS_INTERFACE
  value: "public"
{{- else }}
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name: OS_INTERFACE
  value: "internal"
{{- end }}
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
{{- if .Values.global.is_global_region }}
- name: OS_REGION_NAME
  value: global
{{- else }}
- name: OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
{{- end }}
{{- end -}}
