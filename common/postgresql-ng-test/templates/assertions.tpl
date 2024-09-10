{{- if and (ne .Release.Namespace "postgresql-test") (not .Values.doNotSetThisInProduction) -}}
  {{/* This chart is only intended for use in the E2E test pipeline for the Postgres image itself. */}}
  {{- fail "Do not use this chart. Please use common/postgresql-ng/ instead." -}}
{{- end -}}
