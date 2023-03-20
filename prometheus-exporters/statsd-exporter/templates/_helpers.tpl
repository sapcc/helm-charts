{{/* Generate the full name. */}}
{{- define "statsd-exporter.fullName" -}}
prometheus-{{ . }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "statsd-exporter.labels" -}}
app.kubernetes.io/name: {{ include "statsd-exporter.fullName" . }}
app.kubernetes.io/component: prometheus-exporter
{{- end -}}

{{/*
Ingress hosts
*/}}
{{- define "ingress-host" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $fullName := include "statsd-exporter.fullName" $name }}
{{ if $root.Values.global.clusterType }}
{{ printf "%s.%s.%s.%s" $fullName $root.Values.global.clusterType $root.Values.global.region $root.Values.global.tld }}
{{ else }}
{{- printf "%s.%s.%s" $fullName $root.Values.global.region $root.Values.global.tld -}}
{{ end }}
{{- end -}}
