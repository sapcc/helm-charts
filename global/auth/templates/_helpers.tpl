{{- define "host" -}}
{{- if and (eq .Values.internet_facing true) -}}
auth.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
auth.{{.Values.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}
