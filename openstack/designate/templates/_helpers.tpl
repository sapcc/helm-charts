{{define "designate_api_endpoint_host_public"}}dns-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "keystone_api_endpoint_host_public"}}
{{- if and (eq .Values.global_setup true) (eq .Values.global.db_region "qa-de-1") -}}
identity-3-qa.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
identity-3.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "rabbitmq_host" -}}
{{- if .Values.global_setup -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else if .Values.rabbitmq_cluster.enabled -}}
{{.Release.Name}}-rabbitmq-cluster.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "joinKey" -}}
{{range $item, $_ := . -}}{{$item | replace "." "_" -}},{{- end}}
{{- end -}}

{{- define "loggerIni" -}}
{{range $top_level_key, $value := .}}
[{{$top_level_key}}]
keys={{include "joinKey" $value | trimAll ","}}
{{range $item, $values := $value}}
[{{$top_level_key | trimSuffix "s"}}_{{$item | replace "." "_"}}]
{{- if and (eq $top_level_key "loggers") (ne $item "root")}}
qualname={{$item}}
{{- end}}
{{- range $key, $value := $values}}
{{$key}}={{$value}}
{{- end}}
{{- end}}
{{end}}
{{- end -}}


{{- define "migration_job_name" -}}
{{ .Release.Name }}-migration-{{ required ".Values.image_version_designate is missing" .Values.image_version_designate }}{{ if .Values.proxysql.mode }}-proxysql{{ end }}
{{- end }}
