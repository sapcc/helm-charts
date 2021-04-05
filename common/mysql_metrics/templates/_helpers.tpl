{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{ define "metrics_db_host"}}{{- if eq .Values.db_type "pxc" }}{{.Release.Name}}-percona-pxc.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}{{ else }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{- end -}}{{end}}

{{- define "mysql_metrics.db_password" -}}
{{ .Values.global.dbPassword }}
{{- end -}}

{{/* Needed for testing purposes only. */}}
{{define "RELEASE-NAME_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "testRelease_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
