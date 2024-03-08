{{- define "prometheus.defaultRelabelConfig" -}}
- action: replace
  targetLabel: region
  replacement: {{ required ".Values.global.region missing" .global.region }}
- action: replace
  targetLabel: cluster_type
  replacement: {{ required ".Values.global.clusterType missing" .global.clusterType }}
- action: replace
  targetLabel: cluster
  replacement: {{ if .global.cluster }}{{ .global.cluster }}{{ else }}{{ .global.region }}{{ end }}
{{- end -}}


{{- define "metricsEndpoint" -}}
- interval: {{ default "60s" .endpoint.scrapeInterval }}
  scrapeTimeout: {{ default "55s" .endpoint.scrapeTimeout }}
  port: {{ default "metrics" .endpoint.metricsPort }}
  path: {{ default "/metrics" .endpoint.metricsPath }}
  scheme: {{ default "http" .endpoint.httpScheme }}
{{- if .endpoint.basicAuth }}
  basicAuth:
{{ .endpoint.basicAuth | toYaml | indent 8 }}
{{- end }}
  honorLabels: true
  relabelings: 
    - action: labelmap
    {{- if .isService }}
      regex: '__meta_kubernetes_service_label_(.+)'
    {{- else }}
      regex: '__meta_kubernetes_pod_label_(.+)'
    {{- end }}
    - sourceLabels:
        - __meta_kubernetes_namespace
      targetLabel: kubernetes_namespace
    - sourceLabels:
        - __meta_kubernetes_pod_name
      targetLabel: kubernetes_pod_name
{{ include "prometheus.defaultRelabelConfig" .root | indent 4 }}
{{- if .endpoint.customRelabelings }}
{{ .endpoint.customRelabelings | toYaml | indent 4 }}
{{- end }}
{{- if .endpoint.customMetricRelabelings }}
  metricRelabelings:
{{ .endpoint.customMetricRelabelings | toYaml | indent 4 }}
{{- end }}
{{- end -}}
