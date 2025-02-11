{{- define "seeder_environment" }}
- name: COMMAND
    value: "bash /scripts/start"
- name: NAMESPACE
    value: {{ .Release.Namespace }}
{{- if .Values.sentry.enabled }}
- name: SENTRY_DSN
{{- if .Values.sentry.dsn }}
    value: {{ .Values.sentry.dsn | quote}}
{{ else }}
    valueFrom:
    secretKeyRef:
        name: sentry
        key: seeder.DSN
{{- end }}
{{- end }}
{{- if .Values.keystone.authUrl }}
- name:  OS_AUTH_URL
  value: {{ .Values.keystone.authUrl }}/v3
{{- else }}
- name:  OS_AUTH_URL
  value: {{include "keystone_url" .}}/v3
{{- end }}
- name: OS_AUTH_TYPE
  value: v3password
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: internal
- name:  OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: seeder-secret
      key: service_user_password
- name:  OS_PROJECT_DOMAIN_NAME
  value: 'default'
- name:  OS_PROJECT_NAME
  value: 'admin'
- name:  OS_REGION_NAME
  value: {{ quote .Values.global.region }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'admin'
- name: OS_REGION
  value: {{quote .Values.global.region}}
{{- end -}}
