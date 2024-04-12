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
- name: SENTRY_DB_USER
  value: "sentry"
- name: SENTRY_DB_PASSWORD
  valueFrom: { secretKeyRef: { name: '{{ $.Release.Name }}-pguser-sentry', key: postgres-password } }
{{- if .Values.emailHost }}
- name: SENTRY_EMAIL_HOST
  value: {{ .Values.emailHost | squote }}
{{- end }}
{{- if .Values.emailPort }}
- name: SENTRY_EMAIL_PORT
  value: {{ .Values.emailPort | squote }}
{{- end }}
{{- if .Values.emailUser }}
- name: SENTRY_EMAIL_USER
  value: {{ .Values.emailUser | squote }}
{{- end }}
{{- if .Values.emailPassword }}
- name: SENTRY_EMAIL_PASSWORD
  value: {{ .Values.emailPassword | squote }}
{{- end }}
{{- if .Values.emailUseSSL }}
- name: SENTRY_EMAIL_USE_SSL
  value: {{ .Values.emailUseSSL | squote }}
{{- end }}
{{- if .Values.emailUseTLS }}
- name: SENTRY_EMAIL_USE_TLS
  value: {{ .Values.emailUseTLS | squote }}
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
