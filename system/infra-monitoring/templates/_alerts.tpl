{{- define "prometheus.alerts" }}
{{/* Generate Prometheus Alert Rules */}}
{{- $values := .Values.global.alerts }}
{{- if $values.enabled }}
{{- range $path, $bytes := .Files.Glob "alerts/*.alerts" }}
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule

metadata:
  name: {{ printf "%s" $path | replace "/" "-" }}
  labels:
    type: alerting-rules
    prometheus: {{ required "$values.prometheus missing" $values.prometheus }}

spec:
{{ printf "%s" $bytes | indent 2 }}

{{- end }}
{{- end }}
{{ end -}}
