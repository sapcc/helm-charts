{{/* vim: set filetype=helm */}}

{{/*
Create a default fully qualified app name.
The limit is 63 chars as per RFC 1035, but we truncate to 48 chars to leave
some space for the name suffixes on replicasets and pods.
*/}}
{{- define "postgres.fullname" -}}
  {{- printf "%s-postgresql" .Release.Name | trunc 48 | replace "_" "-" -}}
{{- end -}}

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}

{{- if .Values.postgresPassword }}
{{- fail "postgres-ng: Setting the password via postgresPassword is no longer supported as it is auto generated on each start. Please remove the value and any vault references!" }}
{{- end }}

{{- if .Values.postgresUser }}
{{- fail "postgres-ng: Changing the superuser away from postgres is no longer supported as it is required for updates. Please create extra users via the users value." }}
{{- end }}
