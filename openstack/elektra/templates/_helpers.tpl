{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 -}}
{{- end -}}

{{- define "postgresql.fullname" -}}
{{- printf "%s-%s" .Release.Name "postgresql" | trunc 24 -}}
{{- end -}}

{{define "keystone_url"}}http://keystone.{{default .Release.Namespace .Values.global.keystoneNamespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3/auth/tokens{{end}}
