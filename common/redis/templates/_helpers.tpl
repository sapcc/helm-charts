{{/* Expand the name of the chart. */}}
{{- define "redis.name" -}}
{{- .Chart.Name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "redis.fullname" -}}
{{- $name := .Chart.Name -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{- if .Values.nameOverride }}
{{- fail "redis: The nameOverride option is no longer supported because we did not see it anyone needing it." }}
{{- end }}
