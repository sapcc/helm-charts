{{define "designate_api_endpoint_host_public"}}dns-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "keystone_api_endpoint_host_public"}}
{{- if and (eq .Values.global.is_global_region true) (eq .Values.global.db_region "qa-de-1") -}}
identity-3-qa.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
identity-3.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{/*
If Designate is deployed in a global setup, use global Percona Cluster URL.
Otherwise, if dbType value is set, use utils.db_url to generate the connection string.
dbType could be set to "mariadb", "pxc-db" or "pxc-global".
Fallback to backward compatible MariaDB helper db_url_mysql.
*/}}
{{- define "designate.db_url" }}
{{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
connection = {{ include "db_url_pxc" . }}
{{- else if .Values.dbType }}
connection = {{ include "utils.db_url" . }}
{{- else }}
connection = {{ include "db_url_mysql" . }}
{{- end }}
{{- end }}

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
  {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
  {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . )  | join "\n" }}
  {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
  {{- .Release.Name }}-migration-{{ substr 0 4 $hash }}-{{ required ".Values.image_version_designate is missing" .Values.image_version_designate }}
{{- end }}


{{- define "designate.rabbitmq_dependencies" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}

{{- define "designate.db_dependencies" }}
  {{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
    {{- .Release.Name }}-percona-pxc
  {{- else }}
    {{- include "utils.db_host" . }}
  {{- end }}
{{- end }}

{{- define "designate.service_dependencies" }}
  {{- template "designate.db_dependencies" . }},{{ template "designate.rabbitmq_dependencies" . }}
{{- end }}
