{{/*
Expand the name of the chart.
*/}}
{{- define "netapp-harvest.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netapp-harvest.fullname" -}}
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
{{- define "netapp-harvest.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netapp-harvest.labels" -}}
helm.sh/chart: {{ include "netapp-harvest.chart" . }}
{{ include "netapp-harvest.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "netappsd.labels" -}}
helm.sh/chart: {{ include "netapp-harvest.chart" . }}
{{ include "netappsd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netapp-harvest.selectorLabels" -}}
{{- if .appValues -}}
app.kubernetes.io/name: {{ include "netapp-harvest.name" . }}
app.kubernetes.io/instance: {{ include "netapp-harvest.fullname" . }}
{{- else -}}
app.kubernetes.io/name: {{ include "netapp-harvest.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{- define "netappsd.selectorLabels" -}}
{{- if .appValues -}}
app.kubernetes.io/name: {{ include "netapp-harvest.name" . }}
app.kubernetes.io/instance: {{ include "netapp-harvest.fullname" . }}-sd
{{- else -}}
app.kubernetes.io/name: {{ include "netapp-harvest.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}


{{- define "prom-scrape-annotations" -}}
prometheus.io/scrape: "true"
prometheus.io/targets: {{ .Values.global.prometheus }}
{{- end }}

{{/*
TODO: use staging netbox in qa
https://{{ required ".Values.global.netbox_host_staging" .Values.global.netbox_host_staging }}
*/}}
{{- define "netbox-host" -}}
{{- if eq .Values.global.region "qa-de-1" -}}
https://{{ required ".Values.global.netbox_host" .Values.global.netbox_host }}
{{- else -}}
https://{{ required ".Values.global.netbox_host" .Values.global.netbox_host }}
{{- end }}
{{- end }}
