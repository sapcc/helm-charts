{{- define "prometheus.defaultRelabelConfig" -}}
- action: replace
  targetLabel: region
  replacement: {{ required ".Values.global.region missing" .Values.global.region }}
- action: replace
  targetLabel: cluster_type
  replacement: {{ required ".Values.global.clusterType missing" .Values.global.clusterType }}
- action: replace
  targetLabel: cluster
  replacement: {{ if .Values.global.cluster }}{{ .Values.global.cluster }}{{ else }}{{ .Values.global.region }}{{ end }}
{{- end -}}
