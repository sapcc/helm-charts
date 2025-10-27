{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "blackbox-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "blackbox-exporter.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hostname" -}}
{{ required ".Values.ingress.hostName missing" .Values.ingress.hostName}}.{{ required ".Values.global.region missing" .Values.global.region}}.{{ required ".Values.global.domain missing" .Values.global.domain}}
{{- end -}}
