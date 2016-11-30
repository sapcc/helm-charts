{{ define "env-vars" -}}
- name: SENTRY_DB_NAME
  value: {{ .Values.postgresql.postgresDatabase }}
- name: SENTRY_POSTGRES_HOST
  value: {{ template "postgresql.fullname" . }}
- name: SENTRY_REDIS_HOST
  value: {{ template "redis.fullname" . }}
- name: SENTRY_REDIS_PORT
  value: "6379" 
- name: SENTRY_REDIS_PASSWORD
  valueFrom: { secretKeyRef: { name: {{ template "redis.fullname" . }}, key: redis-password } }
- name: SENTRY_SECRET_KEY
  valueFrom: { secretKeyRef: { name: {{ template "fullname" . }}, key: sentry-secret-key } }
- name: SENTRY_DB_PASSWORD 
  valueFrom: { secretKeyRef: { name: {{ template "postgresql.fullname" . }}, key: postgres-password } }
{{- if .Values.emailHost }}
- name: SENTRY_EMAIL_HOST
  value: {{ .Values.emailHost | quote }} 
{{- end }}
{{- if .Values.singleOrganization }}
- name: SENTRY_SINGLE_ORGANIZATION
  value: {{ .Values.singleOrganization | quote}} 
{{- end }}
{{- if .Values.githubAppId }}
- name: SENTRY_GITHUB_APP_ID
  value: {{ .Values.githubAppId | quote}} 
{{- end }}
{{- if .Values.githubApiSecret }}
- name: SENTRY_GITHUB_API_SECRET
  valueFrom: { secretKeyRef: { name: {{ template "fullname" . }}, key: github-api-secret } }
{{- end }}
{{- if .Values.useSsl }}
- name: SENTRY_USE_SSL
  value: {{ .Values.useSsl | quote}} 
{{- end }}
{{- range $key,$val := .Values.extraEnvVars }}
- name: {{ $key | quote }}
  value: {{ $val | quote }}
{{- end }}
{{ end }}
