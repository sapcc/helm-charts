{{- define "nova.helpers.ini_sections.api_database" }}

[api_database]
connection = {{ tuple . .Values.apidbName .Values.apidbUser .Values.apidbPassword .Values.mariadb_api.name | include "db_url_mysql" }}
{{- include "ini_sections.database_options_mysql" . }}
{{- end }}

{{- define "cell0_db_path" }}
    {{- tuple . .Values.cell0dbName .Values.cell0dbUser (default .Values.cell0dbPassword .Values.global.dbPassword) | include "db_url_mysql" }}
{{- end }}

{{- define "cell2_db_path" -}}
    {{- if eq .Values.cell2.enabled true -}}
        {{- tuple . .Values.cell2dbName .Values.cell2dbUser (default .Values.cell2dbPassword .Values.global.dbPassword) .Values.mariadb_cell2.name | include "db_url_mysql" }}
    {{- end }}
{{- end }}

{{- define "cell2_db_path_for_exporter" -}}
{{- if eq .Values.cell2.enabled true -}}
mysql://{{.Values.cell2dbUser}}:{{ default .Values.cell2dbPassword .Values.global.dbPassword | urlquery }}@tcp(nova-{{.Values.cell2.name}}-mariadb.{{include "svc_fqdn" .}}:3306)/{{.Values.cell2dbName}}
{{- end -}}
{{- end -}}

{{- define "cell2_transport_url" -}}
rabbit://{{ default "" .Values.global.user_suffix | print .Values.rabbitmq_cell2.users.default.user }}:{{ required "rabbitmq_cell2.users.default.password required" .Values.rabbitmq_cell2.users.default.password | urlquery }}@{{.Chart.Name}}-{{.Values.cell2.name}}-rabbitmq.{{include "svc_fqdn" .}}:{{ .Values.rabbitmq_cell2.port | default 5672 }}{{ .Values.rabbitmq_cell2.virtual_host | default "/" }}
{{- end -}}


{{- define "container_image_nova" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNova%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{- $image_name := ( not (.Values.imageVersion | hasPrefix "rocky") | ternary .Values.imageNameNova (printf "ubuntu-source-nova-%s" ($name | lower)) ) -}}

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


{{- define "nova.helpers.database_services" }}
  {{- $envAll := . }}
  {{- $dbs := dict }}
  {{- range $d := $envAll.Chart.Dependencies }}
    {{- if and (hasPrefix "mariadb" $d.Name) }}
        {{- $db := get $envAll.Values $d.Name }}
        {{- if get $db "enabled" }}
          {{- $_ := set $dbs (print (get $db "name") "-mariadb") $db }}
        {{- end }}
    {{- end }}
  {{- end }}
  {{- keys $dbs | sortAlpha | join "," }}
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

{{- define "nova.helpers.cell01_services" }}
  {{- print .Values.mariadb_api.name "-mariadb," .Values.mariadb.name "-mariadb," (include "nova.helpers.cell01_rabbitmq" .) }}
{{- end }}

{{- define "nova.helpers.cell1_services" }}
  {{- print .Values.mariadb.name "-mariadb," (include "nova.helpers.cell01_rabbitmq" .) }}
{{- end }}

{{- define "nova.helpers.cell2_services" }}
  {{- if .Values.cell2.enabled }}
    {{- print .Values.mariadb_cell2.name "-mariadb," (include "nova.helpers.cell2_rabbitmq" .) }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.all_cell_services" }}
  {{- include "nova.helpers.cell01_services" . }}
  {{- if .Values.cell2.enabled -}}
    ,{{ include "nova.helpers.cell2_services" . }}
  {{- end }}
{{- end }}
