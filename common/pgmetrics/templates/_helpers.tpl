{{- if .Values.db_name }}
{{- fail "db_name is no longer supported, set databases[].name instead" }}
{{- end }}

{{- if .Values.db_host }}
{{- fail "db_host is no longer supported, set databases[].host instead" }}
{{- end }}

{{- if .Values.db_password }}
{{- fail "db_password is no longer supported and automatically managed by postgres-ng" }}
{{- end }}
