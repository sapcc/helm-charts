{{- define "identity_service_url" -}}
https://identity-3.{{.Values.global.region}}.{{.Values.global.tld}}/v3
{{- end }}

{{- define "nova.helpers.ini_sections.api_database" }}

[api_database]
connection = {{ tuple . .Values.apidbName .Values.apidbUser .Values.apidbPassword .Values.mariadb_api.name | include "db_url_mysql" }}
{{- include "ini_sections.database_options_mysql" . }}
{{- end }}

{{- define "cell0_db_path" }}
    {{- tuple . .Values.cell0dbName .Values.cell0dbUser (default .Values.cell0dbPassword .Values.global.dbPassword) | include "db_url_mysql" }}
{{- end }}


{{- define "container_image_nova" -}}
  {{- $name := index . 1 -}}
  {{- with index . 0 -}}
    {{- $version_name := printf "imageVersionNova%s" ($name | lower | replace "-" " " | title | nospace) -}}
    {{ required ".Values.global.registry is missing" .Values.global.registry}}/{{ .Values.imageNameNova }}:{{index .Values $version_name | default .Values.imageVersionNova | default .Values.imageVersion | required "Please set nova.imageVersionNova or similar" }}

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

{{- define "nova.helpers.default_transport_url" }}
{{- $data := merge (pick .Values.rabbitmq "nameOverride" "host" "port" "virtual_host") .Values.rabbitmq.users.default }}
{{- $_ := required ".Values.rabbitmq.users.default.user is required" .Values.rabbitmq.users.default.user }}
{{- $_ := required ".Values.rabbitmq.users.default.password is required" .Values.rabbitmq.users.default.password }}
{{- $data := .Values.rabbitmq.users.default.password | urlquery | set $data "password" }}
transport_url = {{ include "utils.rabbitmq_url" (tuple . $data) }}
{{- end }}

{{- define "console-novnc.conf" }}
{{- $cell_name := index . 1 }}
{{- $config := index . 2 }}
{{- with index . 0 }}
[vnc]
enabled = {{ $config.enabled }}
{{- if $config.enabled }}
server_listen = $my_ip
server_proxyclient_address = $my_ip
novncproxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/{{ $cell_name }}/novnc/vnc_auto.html?path=/{{ $cell_name }}/novnc/websockify
{{- end }}
{{- end }}
{{- end }}
