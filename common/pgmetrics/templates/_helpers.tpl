{{- if .Values.db_name }}
{{- fail "pgmetrics: db_name is no longer supported! Please use .Values.databases instead." }}
{{- end }}
