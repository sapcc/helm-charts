{{- define "api_db_path" }}
  {{- $context := dict "target" "api" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb_api.users }}
  {{- tuple . .Values.apidbName (include "nova.helpers.default_db_user" $context) (include "nova.helpers.default_user_password" $context) (include "nova.helpers.api_db_name" .) .Values.apidbType | include "utils.db_url" }}
{{- end }}

{{- define "cell0_db_path" }}
  {{- $context := dict "target" "cell0" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb.users }}
  {{- tuple . .Values.cell0dbName (include "nova.helpers.default_db_user" $context) (include "nova.helpers.default_user_password" $context) (include "nova.helpers.cell01_db_name" .) .Values.cell0dbType | include "utils.db_url" }}
{{- end }}

{{- define "cell1_db_path" -}}
  {{- $context := dict "target" "cell1" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb.users }}
  {{- tuple . .Values.dbName (include "nova.helpers.default_db_user" $context) (include "nova.helpers.default_user_password" $context) (include "nova.helpers.cell01_db_name" .) .Values.cell1dbType | include "utils.db_url" }}
{{- end }}

{{- define "cell1_transport_url" -}}
  {{- $context := dict "target" "cell1" "defaultUsers" .Values.defaultUsersRabbitMQ "users" .Values.rabbitmq.users }}
  {{- $data := dict
      "user" (include "nova.helpers.default_rabbitmq_user" $context)
      "password" (include "nova.helpers.default_user_password" $context)
      "port" .Values.rabbitmq.port
      "virtual_host" .Values.rabbitmq.virtual_host
      "host" (printf "%s-rabbitmq" .Release.Name)
    }}
  {{- include "utils.rabbitmq_url" (tuple . $data) }}
{{- end -}}

{{- define "cell2_db_path" -}}
  {{- $context := dict "target" "cell2" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb_cell2.users }}
  {{- tuple . .Values.cell2dbName (include "nova.helpers.default_db_user" $context) (include "nova.helpers.default_user_password" $context) (include "nova.helpers.cell2_db_name" .) .Values.cell2dbType | include "utils.db_url" }}
{{- end }}

{{- define "cell2_transport_url" -}}
  {{- $context := dict "target" "cell2" "defaultUsers" .Values.defaultUsersRabbitMQ "users" .Values.rabbitmq_cell2.users }}
  {{- $data := dict
      "user" (include "nova.helpers.default_rabbitmq_user" $context)
      "password" (include "nova.helpers.default_user_password" $context)
      "port" .Values.rabbitmq_cell2.port
      "virtual_host" .Values.rabbitmq_cell2.virtual_host
      "host" (printf "%s-%s-rabbitmq" .Release.Name .Values.cell2.name)
    }}
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


{{- define "job_bin_path" }}
  {{- $name := index . 1 }}
  {{- $subdir := "" }}
  {{- if eq (len .) 3 }}
    {{- $subdir = index . 2 | default "" }}
    {{- if $subdir }}
      {{- $subdir = printf "%s/" $subdir }}
    {{- end }}
  {{- end }}
  {{- with index . 0 }}
    {{- printf "%s/bin/%s_%s.tpl" .Template.BasePath $subdir $name }}
  {{- end }}
{{- end }}

{{- define "job_metadata" }}
  {{- $name := index . 1 }}
  {{- $bin_subdir := "" }}
  {{- if eq (len .) 3 }}
    {{- $bin_subdir = index . 2 }}
  {{- end }}
  {{- with index . 0 }}
labels:
  alert-tier: os
  alert-service: nova
{{ tuple . .Release.Name $name | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 2 }}
annotations:
  bin-hash: {{ include (include "job_bin_path" (tuple . $name $bin_subdir)) . | sha256sum }}
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

{{- define "nova.helpers.api_db_name" }}
  {{- if eq .Values.apidbType "mariadb" }}
    {{- print .Values.mariadb_api.name }}
  {{- else if eq .Values.apidbType "pxc-db" }}
    {{- print .Values.pxc_db_api.name }}
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

{{- define "nova.helpers.cell01_db_name" }}
  {{- if eq .Values.cell1dbType "mariadb" }}
    {{- print .Values.mariadb.name }}
  {{- else if eq .Values.cell1dbType "pxc-db" }}
    {{- print .Values.pxc_db.name }}
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

{{- define "nova.helpers.cell2_db_name" }}
  {{- if eq .Values.cell2dbType "mariadb" }}
    {{- print .Values.mariadb_cell2.name }}
  {{- else if eq .Values.cell2dbType "pxc-db" }}
    {{- print .Values.pxc_db_cell2.name }}
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

{{- define "nova.helpers.database_services" }}
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

{{- /*
Helper function to fetch a value (e.g., password, name, user) from a user object in a users map.
Params:
  .target: the target (e.g., cell0, cell1, cell2, api)
  .users: the users map
  .defaultUsers: the defaultUsers map
  .key: the key to fetch from the user object (e.g., "password", "name", "user")
*/ -}}
{{- define "nova.helpers.default_user_value" }}
  {{- $target := .target | lower }}
  {{- $users := .users }}
  {{- $defaultUsers := .defaultUsers }}
  {{- $key := .key }}
  {{- if not $users }}
    {{ fail (printf "No users map defined for target '%s'. Check your values for .users." $target) }}
  {{- end }}
  {{- if not $defaultUsers }}
    {{ fail (printf "No defaultUsers map defined for target '%s'. Check your values for .defaultUsers." $target) }}
  {{- end }}
  {{- $userKey := index $defaultUsers $target }}
  {{- if not $userKey }}
    {{ fail (printf "No default user mapping for target '%s' in defaultUsers. Check your .Values.defaultUsers* for a key '%s'." $target $target) }}
  {{- end }}
  {{- $user := index $users $userKey }}
  {{- if not $user }}
    {{ fail (printf "No user '%s' found in users map for target '%s'. Check your .users for a key '%s'." $userKey $target $userKey) }}
  {{- end }}
  {{- if not (hasKey $user $key) }}
    {{ fail (printf "No key '%s' for user '%s' in users map for target '%s'. Check your .users['%s'] for a key '%s'." $key $userKey $target $userKey $key) }}
  {{- end }}
  {{- index $user $key }}
{{- end }}

{{- define "nova.helpers.default_user_password" }}
  {{- $params := dict "target" .target "users" .users "defaultUsers" .defaultUsers "key" "password" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.default_db_user" }}
  {{- $params := dict "target" .target "users" .users "defaultUsers" .defaultUsers "key" "name" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.default_rabbitmq_user" }}
  {{- $params := dict "target" .target "users" .users "defaultUsers" .defaultUsers "key" "user" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}
