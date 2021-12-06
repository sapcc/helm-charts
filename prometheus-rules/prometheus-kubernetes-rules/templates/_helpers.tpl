{{/* If the collector is enabled metrics are aggregated and prefixed, so they can be federated easily. */}}
{{- define "prefix" -}}
{{ if .Values.prometheusCollectorName -}}aggregated:{{- end }}
{{- end -}}

{{/* Use the 'label_alert-tier', if it exists on the time series, otherwise use the given default. */}}
{{- define "alertTierLabelOrDefault" -}}
"{{`{{ if $labels.label_alert-tier }}`}}{{`{{ $labels.label_alert-tier}}`}}{{`{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}

{{/* Use the 'label_alert-service', if it exists on the time series, otherwise use the given default. */}}
{{- define "alertServiceLabelOrDefault" -}}
"{{`{{ if $labels.label_alert-service }}`}}{{`{{ $labels.label_alert-service}}`}}{{`{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}
