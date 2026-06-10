{{/*
Expand the name of the chart.
*/}}
{{- define "netapp-monitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netapp-monitoring.fullname" -}}
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
{{- define "netapp-monitoring.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netapp-monitoring.labels" -}}
helm.sh/chart: {{ include "netapp-monitoring.chart" . }}
{{ include "netapp-monitoring.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netapp-monitoring.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netapp-monitoring.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "netapp-monitoring.serviceAccountName" -}}
{{- default "netappsd" .Values.netappsd.serviceAccountName }}
{{- end }}


{{/*
Create harvest basic auth credential entry based on credentials_secret.
*/}}

{{- define "netapp-monitoring.defaultCredentialsYaml" -}}
Defaults:
  username: {{ printf "{{ resolve \"%s/username\" }}" .SecretPath }}
  password: {{ printf "{{ resolve \"%s/password\" }}" .SecretPath }}
{{- end }}


{{- define "netapp-monitoring.credentials-entry" -}}
{{- if eq .Values.netappsd.credentials_secret "local-basic-auth" -}}
{{ include "netapp-monitoring.defaultCredentialsYaml" (dict "SecretPath" "vault+kvv2:///secrets/shared/harvest/harvest-ad/local-user") }}
{{- else if eq .Values.netappsd.credentials_secret "sci-basic-auth" -}}
{{ include "netapp-monitoring.defaultCredentialsYaml" (dict "SecretPath" "vault+kvv2:///secrets/shared/harvest/harvest-ad/sci-user") }}
{{- else if eq .Values.netappsd.credentials_secret "hec-basic-auth" -}}
{{ include "netapp-monitoring.defaultCredentialsYaml" (dict "SecretPath" "vault+kvv2:///secrets/shared/harvest/harvest-ad/hec-user") }}
{{- else if eq .Values.netappsd.credentials_secret "internal-basic-auth" -}}
{{ include "netapp-monitoring.defaultCredentialsYaml" (dict "SecretPath" "vault+kvv2:///secrets/shared/harvest/harvest-ad/internal-user") }}
{{- end }}
{{- end }}

