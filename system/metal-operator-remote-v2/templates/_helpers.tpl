{{/*
=============================================================================
metal-operator-remote-v2 helpers
=============================================================================
*/}}

{{/*
Mode guards.
The dual-deployment-operator injects .Values.mode = "seed" | "shoot".
These helpers return "true" / "false" (string) — safe to use in {{- if }}.
When mode is unset (direct helm install without mode) both return "false".
*/}}
{{- define "dual.seed" -}}
{{- eq .Values.mode "seed" -}}
{{- end }}

{{- define "dual.shoot" -}}
{{- eq .Values.mode "shoot" -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
When fullnameOverride is set (default: "metal-operator"), all objects use that name — load-bearing.
*/}}
{{- define "chart.fullname" -}}
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
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Annotations for sapcc addition templates.
Stamps dual-deployment-operator.cc.sap/origin: additions on every object
authored by this chart (as opposed to upstream subchart objects stamped "upstream"
by the operator itself).
*/}}
{{- define "chart.additionsAnnotations" -}}
dual-deployment-operator.cc.sap/origin: additions
{{- end }}
