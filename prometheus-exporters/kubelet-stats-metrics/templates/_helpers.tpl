{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubelet-stats-metrics.fullname" -}}
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
{{- define "kubelet-stats-metrics.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kubelet-stats-metrics.labels" -}}
helm.sh/chart: {{ include "kubelet-stats-metrics.chart" . }}
{{ include "kubelet-stats-metrics.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kubelet-stats-metrics.selectorLabels" -}}
app.kubernetes.io/name: kubelet-stats-metrics
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "serviceFromLabelsOrDefault" -}}
"{{`{{ if $labels.label_ccloud_service }}{{ $labels.label_ccloud_service }}{{ else }}{{ if $labels.label_alert_service }}{{ $labels.label_alert_service }}{{ else }}`}}{{ . }}{{`{{ end }}{{ end }}`}}"
{{- end -}}

{{- define "supportGroupFromLabelsOrDefault" -}}
"{{`{{ if $labels.label_ccloud_support_group }}{{ $labels.label_ccloud_support_group }}{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}
