{{- if .Values.secret_env }}
{{- range .Values.secret_env }}
{{ .name }}: {{ .value | include "resolve_secret" }}
{{- end }}
{{- else }}
{}
{{- end }}
