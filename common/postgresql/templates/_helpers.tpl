{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 | replace "_" "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 | replace "_" "-" -}}
{{- end -}}

{{define "default_keystone_url"}}http://keystone.{{ default .Release.Namespace .Values.global.keystoneNamespace }}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5000/v3{{end}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{/* Generate the name prefix for the templated Prometheus alerts. */}}
{{- define "alerts.name_prefix" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service | title -}}
{{- end -}}
{{- .Release.Name | title -}}
{{- end -}}

{{/* Generate a label selector for finding our own backup metrics. */}}
{{- define "alerts.backup_metrics_selector" -}}
  {{- if .Values.backup.splitDeployment -}}
    {name="{{ .Release.Name }}-pgbackup"}
  {{- else -}}
    {app=~"{{ template "fullname" . }}"}
  {{- end -}}
{{- end -}}

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}
