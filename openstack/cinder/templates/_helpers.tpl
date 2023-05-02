{{- define "cinder.migration_job_name" -}}
cinder-migration-job-{{.Values.imageVersion | required "Please set cinder.imageVersion or similar"}}{{- if .Values.proxysql.mode}}-{{ .Values.proxysql.mode | replace "_" "-" }}{{ end }}
{{- end }}
