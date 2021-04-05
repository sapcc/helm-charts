{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "redis.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 -}}
{{- end -}}

{{- define "redis.image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Values.image.tag missing" .Values.image.tag -}}
{{- end -}}

{{- define "redis.metrics.image" -}}
{{- required ".Values.metrics.image.repository missing" .Values.metrics.image.repository -}}:{{- required ".Values.metrics.image.tag missing" .Values.metrics.image.tag -}}
{{- end -}}
