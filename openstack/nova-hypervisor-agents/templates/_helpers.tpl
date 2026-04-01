{{- define "identity_service_url" -}}
https://identity-3.{{.Values.global.region}}.{{.Values.global.tld}}/v3
{{- end }}

{{- define "console-novnc.conf" }}
{{- $cell_name := index . 1 }}
{{- $config := index . 2 }}
{{- with index . 0 }}
[vnc]
enabled = {{ $config.enabled }}
{{- if $config.enabled }}
novncproxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/{{ $cell_name }}/novnc/vnc_auto.html?path=/{{ $cell_name }}/novnc/websockify
server_listen = $my_ip
server_proxyclient_address = $my_ip
{{- end }}
{{- end }}
{{- end }}

{{- define "console-serial.conf" }}
{{- $cell_name := index . 1 }}
{{- $config := index . 2 }}
{{- with index . 0 }}
[serial_console]
enabled = {{ $config.enabled }}
  {{- if $config.enabled }}
base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/{{ $cell_name }}/serial/
proxyclient_address = $my_ip
  {{- end }}
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

{{- define "nova.helpers.default_rabbitmq_user" }}
  {{- $params := dict "target" .target "users" .users "defaultUsers" .defaultUsers "key" "user" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.default_user_password" }}
  {{- $params := dict "target" .target "users" .users "defaultUsers" .defaultUsers "key" "password" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- /*
  Returns the active cell ID based on the availability zone and enabled cells in the environment.
  The function iterates through a predefined list of cell IDs, checks if they are enabled, and if their corresponding
  cell name matches the suffix of the availability zone. If a match is found, that cell ID is returned as the active
  cell. If no match is found, it defaults to "cell1".

  Example:
  - include "nova.helpers.get_active_cell" .Values => "cell2"
*/ -}}
{{- define "nova.helpers.get_active_cell" }}
  {{- $activeCell := "cell1" }}
  {{- $az := .Values.availability_zone | required "availability_zone is required" }}
  {{- range $cellId := list "cell2" "cell3" "cell4" "cell5" }}
    {{- $cell := get $.Values $cellId | default dict }}
    {{- if and (hasKey $cell "enabled") (index $cell.enabled) }}
    {{- $cellName := include "nova.helpers.cell_name" (tuple $ $cellId) }}
      {{- if hasSuffix $az $cellName }}
        {{- $activeCell = $cellId }}
        {{- break }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $activeCell }}
{{- end }}

{{- define "nova.helpers.get_rabbitmq_by_cell" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqChartAlias := include "nova.helpers.cell_rabbitmq_chart_alias" (tuple $envAll $cellId) }}
  {{- get $envAll.Values $rmqChartAlias | toJson }}
{{- end }}

{{- define "nova.helpers.cell_name" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $cellName := "" }}
  {{- if has $cellId (list "cell1") }}
    {{- $cellName = $cellId }}
  {{- else }}
    {{- $msgNameReq := printf "'.Values.%s.name' is required for cell '%s'" $cellId $cellId }}
    {{- $cellValues := get $envAll.Values $cellId | required $msgNameReq }}
    {{- $cellName = get $cellValues "name" | required $msgNameReq }}
  {{- end }}
  {{- print $cellName }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_chart_alias" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $aliasSuffix := "" }}
  {{- if not (has $cellId (list "cell1")) }}
    {{- $aliasSuffix = printf "_%s" $cellId }}
  {{- end }}
  {{- $rmqChartAlias := printf "%s%s" "rabbitmq" $aliasSuffix }}
  {{- if not (hasKey $envAll.Values $rmqChartAlias) }}
    {{- fail (printf "No RabbitMQ chart '%s' found for cell '%s'" $rmqChartAlias $cellId )}}
  {{- end }}
  {{- print $rmqChartAlias }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_default_user" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqValues := include "nova.helpers.cell_rabbitmq_chart_alias" (tuple $envAll $cellId) | get $envAll.Values }}
  {{- $params := dict "target" $cellId "users" $rmqValues.users "defaultUsers" $envAll.Values.defaultUsersRabbitMQ "key" "user" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_default_password" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqValues := include "nova.helpers.cell_rabbitmq_chart_alias" (tuple $envAll $cellId) | get $envAll.Values }}
  {{- $params := dict "target" $cellId "users" $rmqValues.users "defaultUsers" $envAll.Values.defaultUsersRabbitMQ "key" "password" }}
  {{- include "nova.helpers.default_user_value" $params }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_host" }}
  {{- $cellId := index . 1 }}
  {{- $rmqHostInfix := "" }}
  {{- if not (has $cellId (list "cell0" "cell1")) }}
    {{- $rmqHostInfix = printf "%s-" (include "nova.helpers.cell_name" .) }}
  {{- end }}
  {{- printf "nova-%srabbitmq" $rmqHostInfix }}
{{- end }}

{{- define "nova.helpers.cell_rabbitmq_url" }}
  {{- $envAll := index . 0 }}
  {{- $cellId := index . 1 }}
  {{- $rmqHost := include "nova.helpers.cell_rabbitmq_host" . }}
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

{{- define "nova.helpers.get_active_cell_transport_url" }}
    {{- $activeCell := include "nova.helpers.get_active_cell" . }}
    {{- include "nova.helpers.cell_rabbitmq_url" (tuple . $activeCell) }}
{{- end }}
