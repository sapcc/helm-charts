{{/*
Expand the name of the chart.
*/}}
{{- define "os-user-rotate.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "os-user-rotate.fullname" -}}
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
{{- define "os-user-rotate.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "os-user-rotate.labels" -}}
helm.sh/chart: {{ include "os-user-rotate.chart" . }}
{{ include "os-user-rotate.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "os-user-rotate.selectorLabels" -}}
app.kubernetes.io/name: {{ include "os-user-rotate.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "os-user-rotate.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "os-user-rotate.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Resolve secret and replace single quote with double single quote
This resolved secret could be put inside the single-quoted string inside yaml
*/}}
{{- define "os-user-rotate.resolve_vault_ref" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" {{"}}"}}
    {{- else -}}
        {{ $str }}
    {{- end -}}
{{- end -}}

{{/*
Construct username — required, must not be blank
*/}}
{{- define "os-user-rotate.usernameResolved" -}}
{{- $user := required ".Values.username missing" .Values.username -}}
{{- if not (hasPrefix "vault+kvv2" $user) -}}
{{- if eq (trim $user) "" -}}
{{- fail ".Values.username must not be a blank string" -}}
{{- end -}}
{{- end -}}
{{ include "os-user-rotate.resolve_vault_ref" $user }}
{{- end -}}

{{/*
Construct password — required, must not be blank
*/}}
{{- define "os-user-rotate.passwordResolved" -}}
{{- $pass := required ".Values.password missing" .Values.password -}}
{{- if not (hasPrefix "vault+kvv2" $pass) -}}
{{- if eq (trim $pass) "" -}}
{{- fail ".Values.password must not be a blank string" -}}
{{- end -}}
{{- end -}}
{{ include "os-user-rotate.resolve_vault_ref" $pass }}
{{- end -}}
