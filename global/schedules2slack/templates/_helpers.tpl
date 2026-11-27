{{- define "chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "name" -}}
{{- "schedules2slack" -}}
{{- end -}}

{{/* Keep image pins intact in images, but use the readable tag in metadata. */}}
{{- define "schedules2slack.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{/* Kubernetes label values must be bounded and start/end with alphanumerics. */}}
{{- define "schedules2slack.image.versionLabel" -}}
{{- $tag := include "schedules2slack.image.tag" . -}}
{{- $label := regexReplaceAll "[^a-zA-Z0-9_.-]" $tag "_" | trunc 63 -}}
{{- regexReplaceAll "^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$" $label "" -}}
{{- end -}}
