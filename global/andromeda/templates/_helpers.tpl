{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "andromeda.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "andromeda.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "andromeda.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "andromeda.labels" -}}
app.kubernetes.io/name: {{ include "andromeda.name" . }}
helm.sh/chart: {{ include "andromeda.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "andromeda.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "andromeda.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{define "andromeda_keystone_api_endpoint_internal"}}keystone.{{ required ".Values.global.keystoneNamespace required" .Values.global.keystoneNamespace }}.svc.kubernetes.{{ include "host_fqdn" . }}{{end}}
{{define "andromeda_keystone_global_api_endpoint_internal"}}keystone-global.{{ required ".Values.global.keystoneNamespace required" .Values.global.keystoneNamespace }}{{end}}

{{- define "andromeda_api"}}
{{- if .Values.qa -}}
  gtm-qa.{{ include "host_fqdn" . }}
{{- else }}
  {{- include "andromeda_api_endpoint_public" . }}
{{- end }}
{{- end }}

{{- define "andromeda.database_service" -}}
{{- if .Values.mariadb.enabled -}}
  {{ include "andromeda.fullname" . }}-mariadb
{{- else if .Values.postgresql.enabled -}}
  {{ include "andromeda.fullname" . }}-postgresql
{{- end -}}
{{- end -}}

