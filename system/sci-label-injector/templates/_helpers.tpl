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
The comma-separated registry host allowlist (SCI_ALLOWED_REGISTRIES). The injector
matches the image's registry host exactly, so every entry is a bare host (no path,
no wildcard, no regexp). The default is the three Keppel hosts that serve
application images: the current-region registry (global.registry), the
alternate-region registry (global.registryAlternateRegion), and global. Those two
globals carry a repository path (e.g. keppel.<region>.cloud.sap/ccloud), so the path
is stripped to the host. Hosts listed in sci.allowedRegistries are added on top
(union), so operators can allow extra hosts without losing the defaults. Empty
entries are skipped and duplicates removed.
*/}}
{{- define "sci-label-injector.allowedRegistries" -}}
{{- $hosts := list -}}
{{- with .Values.global.registry -}}
{{- $hosts = append $hosts (splitList "/" . | first) -}}
{{- end -}}
{{- with .Values.global.registryAlternateRegion -}}
{{- $hosts = append $hosts (splitList "/" . | first) -}}
{{- end -}}
{{- $hosts = append $hosts "keppel.global.cloud.sap" -}}
{{- range (splitList "," (.Values.sci.allowedRegistries | default "")) -}}
{{- $hosts = append $hosts . -}}
{{- end -}}
{{- $seen := dict -}}
{{- $out := list -}}
{{- range $hosts -}}
{{- $h := trim . -}}
{{- if and $h (not (hasKey $seen $h)) -}}
{{- $_ := set $seen $h true -}}
{{- $out = append $out $h -}}
{{- end -}}
{{- end -}}
{{- join "," $out -}}
{{- end }}
