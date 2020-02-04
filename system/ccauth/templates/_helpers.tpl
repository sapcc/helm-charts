{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "ccauth.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ccauth.fullname" -}}
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
{{- define "ccauth.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "ccauth.labels" -}}
helm.sh/chart: {{ include "ccauth.chart" . }}
{{ include "ccauth.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ccauth.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ccauth.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Hostname
*/}}
{{- define "ccauth.hostname" -}}
{{- printf "ccauth.%s.cloud.sap" .Values.global.region -}}
{{- end -}}


{{/*
Keystone Host
*/}}
{{- define "ccauth.keystone.host" -}}
{{- if .Values.ccauth.keystone.host }}
{{- printf "%s" .Values.ccauth.keystone.host -}}
{{- else }}
{{- printf "https://identity-3.%s.cloud.sap/v3" .Values.global.region -}}
{{- end }}
{{- end -}}


{{/*
LDAP Host
*/}}
{{- define "ccauth.ldap.host" -}}
{{- if .Values.ccauth.ldap.host }}
{{- printf "%s" .Values.ccauth.ldap.host -}}
{{- else if (contains .Values.global.region "qa") }}
{{- printf "ldap-qa.global.cloud.sap:636" -}}
{{- else }}
{{- printf "ldap.global.cloud.sap:636" -}}
{{- end }}
{{- end -}}


