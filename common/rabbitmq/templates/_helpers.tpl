{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "template" -}}
{{- $template := index . 0 -}}
{{- $context := index . 1 -}}
{{- $v := $context.Template.Name | split "/" -}}
{{- $last := sub (len $v) 1 | printf "_%d" | index $v -}}
{{- $wtf := printf "%s%s" ($context.Template.Name | trimSuffix $last) $template -}}
{{ include $wtf $context }}
{{- end -}}
