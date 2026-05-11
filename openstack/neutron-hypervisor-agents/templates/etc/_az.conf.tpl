{{- if .Values.defaults.availability_zone -}}
[agent]
availability_zone = {{ .Values.defaults.availability_zone }}
{{- end }}
{{- if .Values.defaults.scheduling_disabled }}
scheduling_disabled = {{ .Values.defaults.scheduling_disabled }}
{{- end -}}
