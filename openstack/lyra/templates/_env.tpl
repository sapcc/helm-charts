{{- define "env.vars" -}}
- name: RAILS_ENV
  value: {{ .Values.railsEnv }}
- name: POSTGRES_SERVICE_HOST
  value: {{ template "postgresql.fullname" . }}
- name: MONSOON_OPENSTACK_AUTH_API_ENDPOINT
  value: {{ .Values.auth.endpoint }}
- name: MONSOON_OPENSTACK_AUTH_API_USERID
  value: {{ .Values.auth.userID }}
- name: MONSOON_OPENSTACK_AUTH_API_DOMAIN
  value: {{ .Values.auth.userDomainName }}
- name: MONSOON_SWIFT_USERNAME
  value: {{ .Values.auth.swift.username }}
- name: MONSOON_SWIFT_USER_DOMAIN_ID
  value: {{ .Values.auth.swift.userDomainId}}
- name: MONSOON_SWIFT_PROJECT_NAME
  value: {{ .Values.auth.swift.projectName }}
- name: MONSOON_SWIFT_PROJECT_DOMAIN_NAME
  value: {{ .Values.auth.swift.projectDomainName }}
- name: MONSOON_DB_PASSWORD
  valueFrom: { secretKeyRef:    { name: {{ template "postgresql.fullname" . }}, key: postgres-password  } }
- name: SECRET_KEY_BASE
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: secretKey } }
- name: MONSOON_OPENSTACK_AUTH_API_PASSWORD
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: auth.password } }
- name: MONSOON_SWIFT_PASSWORD
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: auth.swift.password } }
- name: MONSOON_SWIFT_TEMP_URL_KEY
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: auth.swift.tempURLKey } }
{{- if .Values.sentryDSN }}
- name: SENTRY_DSN
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: sentryDsn } }
{{- end }}
{{- end -}}
