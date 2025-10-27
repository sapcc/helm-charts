{{/* Render the auth hostname */}}
{{- define "idproxy.auth.hostname" -}}
{{- printf "%s.%s" "auth" (required "global.dnsDomain missing" .Values.global.dnsDomain) }}
{{- end }}
