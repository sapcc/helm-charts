{{- define "placement_project" -}}
{{ if contains "rocky" .Values.imageVersion }}nova{{ else }}placement{{ end }}
{{- end -}}
