{{/*
SPDX-FileCopyrightText: 2026 SAP SE or an SAP affiliate company

SPDX-License-Identifier: Apache-2.0
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "persephone-liquid-apiserver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "persephone-liquid-apiserver.fullname" -}}
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
{{- define "persephone-liquid-apiserver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "persephone-liquid-apiserver.labels" -}}
helm.sh/chart: {{ include "persephone-liquid-apiserver.chart" . }}
{{ include "persephone-liquid-apiserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app: persephone
role: liquid-apiserver
region: {{ .Values.region }}
landscape: {{ .Values.landscape }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "persephone-liquid-apiserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "persephone-liquid-apiserver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: persephone
role: liquid-apiserver
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "persephone-liquid-apiserver.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name }}
{{- else }}
{{- printf "%s-%s-persephone-liquid-apiserver" .Values.region .Values.landscape | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
