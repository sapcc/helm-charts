{{/*
Expand the name of the chart.
*/}}
{{- define "sci-label-injector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sci-label-injector.fullname" -}}
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
{{- define "sci-label-injector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sci-label-injector.labels" -}}
helm.sh/chart: {{ include "sci-label-injector.chart" . }}
{{ include "sci-label-injector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sci-label-injector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sci-label-injector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sci-label-injector.serviceAccountName" -}}
{{- include "sci-label-injector.fullname" .}}
{{- end }}

{{/*
The comma-separated registry allowlist (SCI_ALLOWED_REGISTRIES). Falls back to
the Keppel hosts that serve application images when sci.allowedRegistries is
unset: the global host, plus the regional host when global.region is known.
*/}}
{{- define "sci-label-injector.allowedRegistries" -}}
{{- if .Values.sci.allowedRegistries }}
{{- .Values.sci.allowedRegistries }}
{{- else if .Values.global.region }}
{{- printf "keppel.global.cloud.sap,keppel.%s.cloud.sap" .Values.global.region }}
{{- else }}
{{- "keppel.global.cloud.sap" }}
{{- end }}
{{- end }}
