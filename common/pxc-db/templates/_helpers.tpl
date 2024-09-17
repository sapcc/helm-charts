{{/*
Expand the name of the chart.
*/}}
{{- define "pxc-db.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pxc-db.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pxc-db.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pxc-db.labels" -}}
helm.sh/chart: {{ include "pxc-db.chart" . }}
{{ include "pxc-db.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: {{ .Chart.Name }}
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pxc-db.selectorLabels" -}}
app: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "pxc-db.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Prometheus labels
*/}}
{{- define "pxc-db.metricsAnnotations" -}}
{{- if .Values.metrics.enabled }}
prometheus.io/scrape: "true"
prometheus.io/targets: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}
{{- end }}
{{- end -}}

{{/*
Default pod labels for linkerd
*/}}
{{- define "pxc-db.linkerdPodAnnotations" -}}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested $.Values.linkerd.enabled }}
linkerd.io/inject: "enabled"
config.alpha.linkerd.io/proxy-enable-native-sidecar: "true"
config.linkerd.io/opaque-ports: "3306,3307,3009,4444,4567,4568,33060,33062"
{{- end }}
{{- end -}}

{{/*
Default service labels for linkerd
*/}}
{{- define "pxc-db.linkerdServiceAnnotations" -}}
{{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested $.Values.linkerd.enabled }}
config.linkerd.io/opaque-ports: "3306,3307,3009,4444,4567,4568,33060,33062"
{{- end }}
{{- end -}}

{{- define "pxc-db.resolve_secret" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" {{"}}"}}
    {{- else -}}
        {{ $str }}
{{- end -}}
{{- end -}}

{{- define "pxc-db.resolve_secret_squote" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | replace "'" "''" | squote {{"}}"}}
    {{- else -}}
        {{ $str | replace "'" "''" | squote }}
{{- end -}}
{{- end -}}
