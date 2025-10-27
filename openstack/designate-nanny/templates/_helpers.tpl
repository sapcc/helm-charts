{{define "keystone_api_endpoint_host_public"}}
{{- if and .Values.global.is_global_region (eq .Values.global.db_region "qa-de-1") -}}
identity-3-qa.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
identity-3.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}
