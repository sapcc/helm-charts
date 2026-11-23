{{/* Keep image pins intact; use only the readable tag for metadata. */}}
{{- define "metis.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{/* Kubernetes label values must be bounded and start/end with alphanumerics. */}}
{{- define "metis.image.label" -}}
{{- $tag := include "metis.image.tag" . -}}
{{- $label := regexReplaceAll "[^a-zA-Z0-9_.-]" $tag "_" | trunc 63 -}}
{{- regexReplaceAll "^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$" $label "" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metis.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
