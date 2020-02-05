{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.name missing" .Values.name -}}-mariadb
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{define "keystone_url"}}http://keystone.{{ default .Release.Namespace .Values.global.keystoneNamespace }}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3{{end}}

{{/* Needed for testing purposes only. */}}
{{define "RELEASE-NAME_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "testRelease_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
