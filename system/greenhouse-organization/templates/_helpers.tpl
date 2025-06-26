{{/*
Expand the name of the chart.
*/}}
{{- define "greenhouse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "greenhouse.fullname" -}}
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
{{- define "greenhouse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "greenhouse.labels" -}}
helm.sh/chart: {{ include "greenhouse.chart" . }}
{{ include "greenhouse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "greenhouse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "greenhouse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "greenhouse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "greenhouse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Check if global.dex.backend is postgres then the postgressql part need to be enabled as well
*/}}
{{- if and (eq .Values.global.dex.backend "postgres") (eq .Values.postgresqlng.enabled "false") }}
{{- fail "dex.backend: Setting the dex.backend to postgres requires that you enable and configure postgresql" }}
{{- end }}
{{/*
Comment out for now to support the rollout of the new dex backend
{{- if and (eq .Values.global.dex.backend "kubernetes") (eq .Values.postgresqlng.enabled "true") }}
{{- fail "dex.backend: Setting the dex.backend to kubernetes does not require postgresql enabled" }}
{{- end }}
*/}}

{{/* Render the auth hostname */}}
{{- define "idproxy.auth.hostname" -}}
{{- printf "%s.%s" "auth" (required "global.dnsDomain missing" .Values.global.dnsDomain) }}
{{- end }}
