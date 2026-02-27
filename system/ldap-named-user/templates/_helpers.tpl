{{/*
Expand the name of the chart.
*/}}
{{- define "ldap-named-user.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ldap-named-user.fullname" -}}
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
{{- define "ldap-named-user.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ldap-named-user.labels" -}}
helm.sh/chart: {{ include "ldap-named-user.chart" . }}
{{ include "ldap-named-user.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ldap-named-user.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ldap-named-user.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ldap-named-user.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ldap-named-user.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Resolve secret and replace single quote with double single quote
This resolved secret could be put inside the single-quoted string inside yaml
*/}}
{{- define "ldap-named-user.resolve_vault_ref" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | replace "'" "''" {{"}}"}}
    {{- else -}}
        {{ $str | replace "'" "''" }}
{{- end -}}
{{- end -}}

{{/*
Construct ldapUser
*/}}
{{- define "ldap-named-user.ldapUserResolved" -}}
    {{ include "ldap-named-user.resolve_vault_ref" (required ".Values.ldapBindUser missing" .Values.ldapBindUser) }}
{{- end -}}

{{/*
Construct ldapPassword
*/}}
{{- define "ldap-named-user.ldapPassResolved" -}}
    {{ include "ldap-named-user.resolve_vault_ref" (required ".Values.ldapBindPassword missing" .Values.ldapBindPassword) }}
{{- end -}}
