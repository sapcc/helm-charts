{{- define "prometheus.federatedMetricsConfig" -}}
params:
  'match[]':
    {{- range $_, $name := . }}
    - '{__name__=~"^{{ $name }}$"}'
    {{- end }}
{{- end -}}
