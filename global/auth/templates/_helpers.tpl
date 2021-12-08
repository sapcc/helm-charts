{{- define "host" -}}
{{- if eq .Values.internet_facing "true" -}}
auth.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
auth.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}
