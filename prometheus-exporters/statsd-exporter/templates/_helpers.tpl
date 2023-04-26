{{/*
Names
*/}}
{{- define "statsd-exporter.name" -}}
{{- printf "%s" . | trunc 63 -}}
{{- end -}}

{{- define "statsd-exporter.fullName" -}}
{{- printf "prometheus-%s" . | trunc 63 -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "statsd-exporter.labels" -}}
app.kubernetes.io/name: {{ include "statsd-exporter.name" . }}
{{ include "statsd-exporter.selectorLabels" . }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "statsd-exporter.selectorLabels" -}}
app.kubernetes.io/instance: cc3test-{{ include "statsd-exporter.name" . }}
{{- end -}}

{{/*
Port
*/}}
{{- define "statsd-ports" -}}
{{- printf ":%s" . -}}
{{- end -}}

{{/*
Ingress hosts
*/}}
{{- define "ingress-host" -}}
{{- $ := index . 0 -}}
{{- $exporter := index . 1 -}}
{{- $fullName := include "statsd-exporter.fullName" $exporter.name -}}
{{- if $.Values.global.clusterType -}}
{{- printf "%s.%s.%s.%s" $fullName $.Values.global.clusterType $.Values.global.region $.Values.global.tld -}}
{{- else -}}
{{- printf "%s.%s.%s" $fullName $.Values.global.region $.Values.global.tld -}}
{{- end -}}
{{- end -}}