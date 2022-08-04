{{/* If the collector is enabled metrics are aggregated and prefixed, so they can be federated easily. */}}
{{- define "prefix" -}}
{{ if .Values.prometheusCollectorName -}}aggregated:{{- end }}
{{- end -}}

{{- /*
Use the 'label_alert_tier', if it exists on the time series, otherwise use the given default.
Note: The pods define the 'alert-tier' label but Prometheus replaces the hyphen with an underscore.
*/}}
{{- define "alertTierLabelOrDefault" -}}
"{{`{{ if $labels.label_alert_tier }}{{ $labels.label_alert_tier}}{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}

{{- /*
Use the 'label_alert_service', if it exists on the time series, otherwise use the given default.
Note: The pods define the 'alert-service' label but Prometheus replaces the hyphen with an underscore.
*/}}
{{- define "serviceLabelOrDefault" -}}
"{{`{{ if $labels.label_cc_service }}{{ $labels.label_cc_service }}{{ else }}{{ if $labels.label_alert_service }}{{ $labels.label_alert_service }}{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}{{ end }}`}}"
{{- end -}}

{{- define "supportGroupLabelOrDefault" -}}
"{{`{{ if $labels.label_cc_support_group }}{{ $labels.label_cc_support_group }}{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}
