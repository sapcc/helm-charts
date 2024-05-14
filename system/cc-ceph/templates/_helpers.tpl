{{/*
Expand the name of the chart.
*/}}
{{- define "cc-ceph.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cc-ceph.fullname" -}}
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
{{- define "cc-ceph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cc-ceph.labels" -}}
helm.sh/chart: {{ include "cc-ceph.chart" . }}
{{ include "cc-ceph.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cc-ceph.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cc-ceph.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cc-ceph.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cc-ceph.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Function to escape CEPH special characters */}}
{{/* following the https://docs.ceph.com/en/latest/rados/configuration/ceph-conf docs */}}
{{- define "cc-ceph.escapePassword" -}}
    {{- $value := . -}}
    {{- $escaped := "" -}}
    {{- $length := len $value -}}
    {{- range $index := until $length -}}
        {{- $char := index $value $index -}}
        {{- if or (eq $char '=') (eq $char '#') (eq $char ';') (eq $char '[') -}}
            {{- $escaped = printf "%s\\%c" $escaped $char -}}
        {{- else -}}
            {{- $escaped = printf "%s%c" $escaped $char -}}
        {{- end -}}
    {{- end -}}
    {{- $escaped -}}
{{- end -}}
