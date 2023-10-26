{{/* vim: set filetype=gotpl: */}}

{{/*
Create a default fully qualified app name.
The limit is 63 chars as per RFC 1035, but we truncate to 48 chars to leave
some space for the name suffixes on replicasets and pods.
*/}}
{{- define "fullname" -}}
  {{- printf "%s-%s" .Release.Name .Chart.Name | trunc 48 | replace "_" "-" -}}
{{- end -}}

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

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}
