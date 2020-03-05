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

{{- define "db_host"}}
{{- if .Values.global.clusterDomain }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{- end -}}
{{- end}}
{{define "memcached_host"}}{{ if .Values.global.clusterDomain }}{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}{{end}}
{{define "rabbitmq_host"}}{{ if .Values.global.clusterDomain }}{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}{{end}}

{{/*
To satisfy common/mysql_metrics :(
*/}}

{{define "keystone_db_host"}}{{- if .Values.global.clusterDomain }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{- end -}}{{end}}

