{{- define "neutron.migration_job_name" -}}
neutron-migration-{{ .Values.imageVersion | required "Please set neutron.imageVersion or similar"}}{{ if .Values.proxysql }}{{ if .Values.proxysql.mode }}-{{ .Values.proxysql.mode | replace "_" "-" }}{{ end }}{{ end }}
{{- end }}
