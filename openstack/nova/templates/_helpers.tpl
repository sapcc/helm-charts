{{- define "nova.helpers.ini_sections.api_database" }}

[api_database]
connection = {{ tuple . .Values.apidbName .Values.apidbUser .Values.apidbPassword .Values.mariadb_api.name .Values.apidbType | include "utils.db_url" }}
{{- include "ini_sections.database_options_mysql" . }}
{{- end }}

{{- define "cell0_db_path" }}
    {{- tuple . .Values.cell0dbName .Values.cell0dbUser (default .Values.cell0dbPassword .Values.global.dbPassword) .Values.mariadb.name .Values.cell0dbType | include "utils.db_url" }}
{{- end }}

{{- define "cell1_db_path" -}}
    {{- tuple . .Values.dbName .Values.dbUser (default .Values.dbPassword .Values.global.dbPassword) .Values.mariadb.name .Values.cell1dbType | include "utils.db_url" }}
{{- end }}

{{- define "cell1_transport_url" -}}
{{- $data := merge (pick .Values.rabbitmq "port" "virtual_host") .Values.rabbitmq.users.default }}
{{- $_ := set $data "host" (printf "%s-rabbitmq" .Release.Name ) }}
{{- $_ := required ".Values.rabbitmq.users.default.user is required" .Values.rabbitmq.users.default.user }}
{{- $_ := required ".Values.rabbitmq.users.default.password is required" .Values.rabbitmq.users.default.password }}
{{- include "utils.rabbitmq_url" (tuple . $data) }}
{{- end -}}

{{- define "cell2_db_path" -}}
    {{- if eq .Values.cell2.enabled true -}}
        {{- tuple . .Values.cell2dbName .Values.cell2dbUser (default .Values.cell2dbPassword .Values.global.dbPassword) .Values.mariadb_cell2.name .Values.cell2dbType | include "utils.db_url" }}
    {{- end }}
{{- end }}

{{- define "cell2_db_path_for_exporter" -}}
{{- if eq .Values.cell2.enabled true -}}
mysql://{{ .Values.cell2dbUser | include "mysql_metrics.resolve_secret_for_yaml" }}:{{ default .Values.cell2dbPassword .Values.global.dbPassword | include "mysql_metrics.resolve_secret_for_yaml" }}@tcp(nova-{{.Values.cell2.name}}-mariadb.{{include "svc_fqdn" .}}:3306)/{{.Values.cell2dbName}}
{{- end -}}
{{- end -}}

{{- define "cell2_transport_url" -}}
{{- $data := merge (pick .Values.rabbitmq_cell2 "port" "virtual_host") .Values.rabbitmq_cell2.users.default }}
{{- $_ := set $data "host" (printf "%s-%s-rabbitmq" .Release.Name .Values.cell2.name) }}
{{- $_ := required ".Values.rabbitmq_cell2.users.default.user is required" .Values.rabbitmq_cell2.users.default.user }}
{{- $_ := required ".Values.rabbitmq_cell2.users.default.password is required" .Values.rabbitmq_cell2.users.default.password }}
{{- include "utils.rabbitmq_url" (tuple . $data) }}
{{- end -}}


{{- define "container_image_nova" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNova%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := .Values.imageNameNova -}}

    {{ required ".Values.global.registry is missing" .Values.global.registry}}/{{$image_name}}:{{index .Values $version_name | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set nova.imageVersionNova or similar" }}

  {{- end -}}
{{- end -}}


{{- define "job_metadata" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
labels:
  alert-tier: os
  alert-service: nova
{{ tuple . .Release.Name $name | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 2 }}
annotations:
  bin-hash: {{ include (print .Template.BasePath "/bin/_" $name ".tpl") . | sha256sum }}
  {{- include "utils.linkerd.pod_and_service_annotation" . | indent 2 }}
  {{- end }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include (print .Template.BasePath "/bin/_" $name ".tpl") . }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set nova.imageVersion or similar"}}
  {{- end }}
{{- end }}

{{/* TODO: Expose and use the logic in the rabbitmq subchart */}}
{{- define "nova.helpers.rabbitmq_name" }}
  {{- $vals := index . 1 }}
  {{- with index . 0 }}
    {{- $name := default "rabbitmq" $vals.nameOverride -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
  {{- end}}
{{- end }}

{{- define "nova.helpers.cell01_rabbitmq" }}
  {{- tuple . .Values.rabbitmq | include "nova.helpers.rabbitmq_name" }}
{{- end }}

{{- define "nova.helpers.cell2_rabbitmq" }}
  {{- tuple . .Values.rabbitmq_cell2 | include "nova.helpers.rabbitmq_name" }}
{{- end }}

{{- define "nova.helpers.api_db" }}
  {{- if eq .Values.apidbType "mariadb" }}
    {{- print .Values.mariadb_api.name "-mariadb" }}
  {{- else if eq .Values.apidbType "pxc-db" }}
    {{- print .Values.pxc_db_api.name "-db-haproxy" }}
  {{- else }}
    {{- fail (print "Unsupported database type for api_db") }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.cell01_db" }}
  {{- if eq .Values.cell1dbType "mariadb" }}
    {{- print .Values.mariadb.name "-mariadb" }}
  {{- else if eq .Values.cell1dbType "pxc-db" }}
    {{- print .Values.pxc_db.name "-db-haproxy" }}
  {{- else }}
    {{- fail (print "Unsupported database type for cell0 and cell1") }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.cell2_db" }}
  {{- if eq .Values.cell2dbType "mariadb" }}
    {{- print .Values.mariadb_cell2.name "-mariadb" }}
  {{- else if eq .Values.cell2dbType "pxc-db" }}
    {{- print .Values.pxc_db_cell2.name "-db-haproxy" }}
  {{- else }}
    {{- fail (print "Unsupported database type for cell2") }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.cell01_services" }}
  {{- print (include "nova.helpers.api_db" .) "," (include "nova.helpers.cell01_db" .) "," (include "nova.helpers.cell01_rabbitmq" .) }}
{{- end }}

{{- define "nova.helpers.cell1_services" }}
  {{- print (include "nova.helpers.cell01_db" .) "," (include "nova.helpers.cell01_rabbitmq" .) }}
{{- end }}

{{- define "nova.helpers.cell2_services" }}
  {{- if .Values.cell2.enabled }}
    {{- print (include "nova.helpers.cell2_db" .) "," (include "nova.helpers.cell2_rabbitmq" .) }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.all_database_services" }}
  {{- include "nova.helpers.api_db" . }},{{ include "nova.helpers.cell01_db" . }}
  {{- if .Values.cell2.enabled -}}
    ,{{ include "nova.helpers.cell2_db" . }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.all_cell_services" }}
  {{- include "nova.helpers.cell01_services" . }}
  {{- if .Values.cell2.enabled -}}
    ,{{ include "nova.helpers.cell2_services" . }}
  {{- end }}
{{- end }}
