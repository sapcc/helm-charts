{{/* vim: set filetype=gotpl: */}}

{{- if eq .Values.postgresDatabase "postgres" }}
  {{- fail "postgresDatabase cannot be set to postgres because that is the name of an internal database!" }}
{{- end }}

{{/*
Create a default fully qualified app name.
The limit is 63 chars as per RFC 1035, but we truncate to 48 chars to leave
some space for the name suffixes on replicasets and pods.
*/}}
{{- define "fullname" -}}
  {{- printf "%s-postgresql" .Release.Name | trunc 48 | replace "_" "-" -}}
{{- end -}}

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}

{{- define "preferredDockerHubMirror" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.dockerHubMirrorAlternateRegion | required ".Values.global.dockerHubMirrorAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.dockerHubMirror | required ".Values.global.dockerHubMirror missing" -}}
  {{- end -}}
{{- end -}}
