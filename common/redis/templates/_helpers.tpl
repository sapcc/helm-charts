{{/* Expand the name of the chart. */}}
{{- define "redis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "redis.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
  The (contains "." $repo) checks if the chart user has overridden the
  repository to refer to a custom registry. If not, the default Docker Hub
  mirror gets used.
*/}}
{{- define "redis.image" -}}
  {{- $repo := required ".Values.image.repository missing" .Values.image.repository -}}
  {{- $tag := required ".Values.image.tag missing" .Values.image.tag -}}
  {{- if contains "." $repo -}}
    {{- $repo -}}:{{- $tag -}}
  {{- else -}}
    {{- required ".Values.global.dockerHubMirror missing" .Values.global.dockerHubMirror -}}/{{- $repo -}}:{{- $tag -}}
  {{- end -}}
{{- end -}}

{{- define "redis.metrics.image" -}}
  {{- $repo := required ".Values.metrics.image.repository missing" .Values.metrics.image.repository -}}
  {{- $tag := required ".Values.metrics.image.tag missing" .Values.metrics.image.tag -}}
  {{- if contains "." $repo -}}
    {{- $repo -}}:{{- $tag -}}
  {{- else -}}
    {{- required ".Values.global.dockerHubMirror missing" .Values.global.dockerHubMirror -}}/{{- $repo -}}:{{- $tag -}}
  {{- end -}}
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- .Values.alerts.service | default .Release.Name -}}
{{- end -}}
