{{/* If the collector is enabled metrics are aggregated and prefixed, so they can be federated easily. */}}
{{- define "prefix" -}}
{{ if .Values.prometheusCollectorName -}}aggregated:{{- end }}
{{- end -}}

{{/* Use the 'label_tier', if it exists on the time series, otherwise use the given default. */}}
{{- define "tierLabelOrDefault" -}}
"{{`{{ if $labels.label_tier }}`}}{{`{{ $labels.label_tier}}`}}{{`{{ else }}`}}{{ required ".default" .default }}{{`{{ end }}`}}"
{{- end -}}

{{/* Use the 'label_service', if it exists on the time series, otherwise use the given default. */}}
{{- define "serviceLabelOrDefault" -}}
"{{`{{ if $labels.label_service }}`}}{{`{{ $labels.label_service}}`}}{{`{{ else }}`}}{{ required ".default" .default }}{{`{{ end }}`}}"
{{- end -}}
