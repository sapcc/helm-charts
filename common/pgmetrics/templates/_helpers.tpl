{{- if .Values.db_name }}
{{- fail "pgmetrics: db_name is no longer supported! Please use .Values.databases instead." }}
{{- end }}

{{- if eq (len .Values.databases) 0 }}
  {{- fail "pgmetrics: needs at least one entry in .Values.databases" }}
{{- end }}

{{/*
Sanitize database name to be RFC 1123 compliant for Kubernetes resource names.
Converts to lowercase and replaces any non-compliant characters with hyphens.
Usage: {{ include "pgmetrics.sanitizeName" "database_name" }}
*/}}
{{- define "pgmetrics.sanitizeName" -}}
{{- . | lower | regexReplaceAll "[^a-z0-9-]+" "-" -}}
{{- end -}}
