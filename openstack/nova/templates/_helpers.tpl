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

{{- define "nova.helpers.api_services" }}
  {{- $services := list }}
  {{- $services = append $services (include "nova.helpers.db_service" (tuple . "api")) }}
  {{- $services = append $services (include "nova.helpers.db_service" (tuple . "cell0")) }}
  {{- $services = append $services (include "nova.helpers.cell_rabbitmq_service" (tuple . "cell1")) }}
  {{- $services | join "," }}
{{- end }}

{{- define "nova.helpers.database_services" }}
  {{- $services := list (include "nova.helpers.db_service" (tuple . "api")) }}
  {{- $envAll := . }}
  {{- range $cellId := include "nova.helpers.cell_ids_nonzero" . | fromJsonArray }}
    {{- $services = append $services (include "nova.helpers.db_service" (tuple $envAll $cellId)) }}
  {{- end }}
  {{- $services | join "," }}
{{- end }}

{{- define "nova.helpers.database_and_rabbitmq_services" }}
  {{- $services := list (include "nova.helpers.db_service" (tuple . "api")) }}
  {{- $envAll := . }}
  {{- range $cellId := include "nova.helpers.cell_ids_nonzero" . | fromJsonArray }}
    {{- $services = append $services (include "nova.helpers.cell_services" (tuple $envAll $cellId)) }}
  {{- end }}
  {{- $services | join "," }}
{{- end }}

{{- /*
  Returns a JSON array of the cell IDs of all enabled cells, except for "cell0".

  Example:
  - include "nova.helpers.cell_ids_nonzero" . | fromJsonArray -> ["cell1", "cell2"]
*/ -}}
{{- define "nova.helpers.cell_ids_nonzero" }}
  {{- $cellIds := list "cell1" }}
  {{- if .Values.cell2.enabled }}
    {{- $cellIds = append $cellIds "cell2" }}
  {{- end }}
  {{- if .Values.cell3.enabled }}
    {{- $cellIds = append $cellIds "cell3" }}
  {{- end }}
  {{- $cellIds | toJson }}
{{- end }}

{{- /*
  Returns a JSON array of the cell IDs of all enabled cells, including "cell0".

  Example:
  - include "nova.helpers.cell_ids_all" . | fromJsonArray -> ["cell0", "cell1", "cell2"]
*/ -}}
{{- define "nova.helpers.cell_ids_all" }}
  {{- $cellIds := include "nova.helpers.cell_ids_nonzero" . | fromJsonArray }}
  {{- $cellIds = prepend $cellIds "cell0" }}
  {{- $cellIds | toJson }}
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

{{- /*
  Database helper functions require the root context and a database ID as a parameter, e.g., (tuple . "cell1").
  Database IDs are, e.g., "api", "cell0", "cell1", "cell2".
*/ -}}

{{- define "nova.helpers.db_type" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $key := printf "%sdbType" $dbId }}
  {{- $dbType := get $envAll.Values $key | required (printf "'.Values.%s' is required for database '%s'" $key $dbId) }}
  {{- $supportedDbTypes := list "mariadb" "pxc-db" }}
  {{- if not (has $dbType $supportedDbTypes) }}
    {{- fail (printf "Unsupported database type '%s' for database '%s'. Supported are: %s" $dbType $dbId ($supportedDbTypes | join ", ")) }}
  {{- end }}
  {{- print $dbType }}
{{- end }}

{{- define "nova.helpers.db_chart_alias" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbType := include "nova.helpers.db_type" . }}
  {{- $aliasSuffix := "" }}
  {{- if not (has $dbId (list "cell0" "cell1")) }}
    {{- $aliasSuffix = printf "_%s" $dbId }}
  {{- end }}
  {{- $dbChartAlias := printf "%s%s" (replace "-" "_" $dbType) $aliasSuffix }}
  {{- if not (hasKey $envAll.Values $dbChartAlias) }}
    {{- fail (printf "No database chart '%s' found for database '%s'" $dbChartAlias $dbId ) }}
  {{- end }}
  {{- print $dbChartAlias }}
{{- end }}

{{- define "nova.helpers.db_name" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbChartAlias := include "nova.helpers.db_chart_alias" . }}
  {{- $dbValues := get $envAll.Values $dbChartAlias }}
  {{- $name := $dbValues.name | required (printf "'.Values.%s.name' is required for database '%s'" $dbChartAlias $dbId) }}
  {{- print $name }}
{{- end }}

{{- define "nova.helpers.db_service" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbType := include "nova.helpers.db_type" . }}
  {{- $dbName := include "nova.helpers.db_name" . }}
  {{- if eq $dbType "mariadb" }}
    {{- print $dbName "-mariadb" }}
  {{- else if eq $dbType "pxc-db" }}
    {{- print $dbName "-db-haproxy" }}
  {{- else }}
    {{- fail (printf "Unsupported database type '%s' for database '%s'. Supported are: mariadb, pxc-db" $dbType $dbId) }}
  {{- end }}
{{- end }}

{{- define "nova.helpers.db_database" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbChartAlias := include "nova.helpers.db_chart_alias" . }}
  {{- $dbValues := get $envAll.Values $dbChartAlias }}
  {{- $dbs := get $dbValues "databases" | required (printf "'.Values.%s.databases' is required for database '%s'" $dbChartAlias $dbId) }}
  {{- $dbDatabase := "" }}
  {{- if eq $dbId "cell0" }}
    {{- $dbDatabase = "nova_cell0" }}
  {{- else }}
    {{- $dbDatabase = include "nova.helpers.db_name" . | replace "-" "_" }}
  {{- end }}
  {{- if not (has $dbDatabase $dbs) }}
    {{- fail (printf "'.Values.%s.databases' does not contain database '%s'" $dbChartAlias $dbDatabase )}}
  {{- end }}
  {{- print $dbDatabase }}
{{- end }}

{{- define "nova.helpers.db_default_user" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbValues := include "nova.helpers.db_chart_alias" . | get $envAll.Values }}
  {{- $params := dict "target" $dbId "users" $dbValues.users "defaultUsers" $envAll.Values.defaultUsersMariaDB "key" "name" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.db_default_password" }}
  {{- $envAll := index . 0 }}
  {{- $dbId := index . 1 }}
  {{- $dbValues := include "nova.helpers.db_chart_alias" . | get $envAll.Values }}
  {{- $params := dict "target" $dbId "users" $dbValues.users "defaultUsers" $envAll.Values.defaultUsersMariaDB "key" "password" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.db_url" }}
  {{- $envAll := index . 0 }}
  {{- $dbDatabase := include "nova.helpers.db_database" . }}
  {{- $dbType := include "nova.helpers.db_type" . }}
  {{- $dbName := include "nova.helpers.db_name" . }}
  {{- $dbUser := include "nova.helpers.db_default_user" . }}
  {{- $dbPassword := include "nova.helpers.db_default_password" . }}
  {{- tuple $envAll $dbDatabase $dbUser $dbPassword $dbName $dbType | include "utils.db_url" }}
{{- end }}

{{- /*
  Cell helper functions require the root context and a cell ID as a parameter, e.g., (tuple . "cell1"). Cell IDs are,
  e.g., "cell0", "cell1", "cell2".
*/ -}}

{{- define "nova.helpers.cell_name" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $cellName := "" }}
  {{- if has $cellId (list "cell0" "cell1") }}
    {{- $cellName = $cellId }}
  {{- else }}
    {{- $msgNameReq := printf "'.Values.%s.name' is required for cell '%s'" $cellId $cellId }}
    {{- $cellValues := get $envAll.Values $cellId | required $msgNameReq }}
    {{- $cellName = get $cellValues "name" | required $msgNameReq }}
  {{- end }}
  {{- print $cellName }}
{{- end }}

{{- define "nova.helpers.cell_services" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $services := list }}
  {{- $services = append $services (include "nova.helpers.db_service" (tuple $envAll $cellId)) }}
  {{- $services = append $services (include "nova.helpers.cell_rabbitmq_service" (tuple $envAll $cellId)) }}
  {{- $services | join "," }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_chart_alias" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $aliasSuffix := "" }}
  {{- if not (has $cellId (list "cell0" "cell1")) }}
    {{- $aliasSuffix = printf "_%s" $cellId }}
  {{- end }}
  {{- $rmqChartAlias := printf "%s%s" "rabbitmq" $aliasSuffix }}
  {{- if not (hasKey $envAll.Values $rmqChartAlias) }}
    {{- fail (printf "No RabbitMQ chart '%s' found for cell '%s'" $rmqChartAlias $cellId )}}
  {{- end }}
  {{- print $rmqChartAlias }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_service" }}
  {{- $envAll := index . 0 }}
  {{- $rmqChartAlias := include "nova.helpers.cell_rabbitmq_chart_alias" . }}
  {{- $rmqValues := get $envAll.Values $rmqChartAlias }}
  {{- $rmqName := default "rabbitmq" $rmqValues.nameOverride }}
  {{- printf "%s-%s" $envAll.Release.Name $rmqName | trunc 63 | replace "_" "-" | trimSuffix "-" }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_default_user" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqValues := include "nova.helpers.cell_rabbitmq_chart_alias" . | get $envAll.Values }}
  {{- $params := dict "target" $cellId "users" $rmqValues.users "defaultUsers" $envAll.Values.defaultUsersRabbitMQ "key" "user" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_default_password" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqValues := include "nova.helpers.cell_rabbitmq_chart_alias" . | get $envAll.Values }}
  {{- $params := dict "target" $cellId "users" $rmqValues.users "defaultUsers" $envAll.Values.defaultUsersRabbitMQ "key" "password" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_url" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqHostInfix := "" }}
  {{- if not (has $cellId (list "cell0" "cell1")) }}
    {{- $rmqHostInfix = printf "%s-" (include "nova.helpers.cell_name" .) }}
  {{- end }}
  {{- $rmqHost := printf "%s-%srabbitmq" $envAll.Release.Name $rmqHostInfix}}
  {{- $rmqChartAlias := include "nova.helpers.cell_rabbitmq_chart_alias" . }}
  {{- $rmqValues := get $envAll.Values $rmqChartAlias }}
  {{- $data := dict
      "user" (include "nova.helpers.cell_rabbitmq_default_user" .)
      "password" (include "nova.helpers.cell_rabbitmq_default_password" .)
      "port" $rmqValues.port
      "virtual_host" $rmqValues.virtual_host
      "host" $rmqHost
    }}
  {{- include "utils.rabbitmq_url" (tuple $envAll $data) }}
{{- end }}
