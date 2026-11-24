{{/* Keep image pins intact; use only the readable tag for metadata. */}}
{{- define "trust-manager.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{/* Kubernetes label values must be bounded and start/end with alphanumerics. */}}
{{- define "trust-manager.image.label" -}}
{{- $tag := include "trust-manager.image.tag" . -}}
{{- $label := regexReplaceAll "[^a-zA-Z0-9_.-]" $tag "_" | trunc 63 -}}
{{- regexReplaceAll "^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$" $label "" -}}
{{- end -}}
