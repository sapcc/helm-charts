{{/* vim: set filetype=helm */}}

{{/*
Create a default fully qualified app name.
The limit is 63 chars as per RFC 1035, but we truncate to 48 chars to leave
some space for the name suffixes on replicasets and pods.
*/}}
{{- define "postgres.fullname" -}}
  {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trunc 48 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default "postgresql" .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trunc 48 | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trunc 48 | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}
