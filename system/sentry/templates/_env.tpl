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
  value: {{ .Values.emailHost | squote }}
{{- end }}
{{- if .Values.serverEmail }}
- name: SENTRY_SERVER_EMAIL
  value: {{ .Values.serverEmail | squote }}
{{- end }}
{{- if .Values.singleOrganization }}
- name: SENTRY_SINGLE_ORGANIZATION
  value: {{ .Values.singleOrganization | squote}}
{{- end }}
{{- if .Values.githubAppId }}
- name: GITHUB_APP_ID
  value: {{ .Values.githubAppId | squote}}
{{- end }}
{{- if .Values.githubApiSecret }}
- name: GITHUB_API_SECRET
  valueFrom: { secretKeyRef: { name: {{ template "fullname" . }}, key: github-api-secret } }
{{- end }}
{{- if .Values.useSsl }}
- name: SENTRY_USE_SSL
  value: {{ .Values.useSsl | squote}}
{{- end }}
{{- range $key,$val := .Values.extraEnvVars }}
- name: {{ $key | squote }}
  value: {{ $val | squote }}
{{- end }}
{{ end }}
