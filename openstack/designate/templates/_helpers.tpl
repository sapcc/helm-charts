{{define "designate_api_endpoint_host_public"}}dns-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{- define "rabbitmq_host" -}}
{{- if .Values.global.clusterDomain -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}
{{- else if .Values.global_setup -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
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
