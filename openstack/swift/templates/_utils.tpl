{{- define "swift_endpoint_host" -}}
    {{- if .Values.proxy_host -}}
        {{.Values.proxy_host}}
    {{- else -}}
        objectstore.{{.Values.global.region}}.{{.Values.global.domain}}
    {{- end -}}
{{- end -}}
