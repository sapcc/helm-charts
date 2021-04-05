{{/* If the collector is enabled metrics are aggregated and prefixed, so they can be federated easily. */}}
{{- define "prefix" -}}
{{ if .Values.prometheusCollectorName -}}aggregated:{{- end }}
{{- end -}}
