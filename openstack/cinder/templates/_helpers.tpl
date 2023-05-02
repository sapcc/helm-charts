{{- define "cinder.migration_job_name" -}}
cinder-migration-{{.Values.imageVersion | required "Please set cinder.imageVersion or similar"}}{{- if .Values.proxysql.mode}}-{{ .Values.proxysql.mode | replace "_" "-" }}{{ end }}
{{- end }}
