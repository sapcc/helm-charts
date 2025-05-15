{{- if .Values.db_name }}
{{- fail "pgmetrics: db_name is no longer supported! Please use .Values.databases instead." }}
{{- end }}

{{- if eq (len .Values.databases) 0 }}
  {{- fail "pgmetrics: needs at least one entry in .Values.databases" }}
{{- end }}
