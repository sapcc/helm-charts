{{- define "host" -}}
{{- if eq .Values.internet_facing "true" -}}
auth.global.{{.Values.global.tld}}
{{- else -}}
auth.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}
