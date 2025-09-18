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

{{- define "cell1_transport_url" -}}
  {{- $context := dict "target" "cell1" "defaultUsers" .Values.defaultUsersRabbitMQ "users" .Values.rabbitmq.users }}
  {{- $data := dict
      "user" (include "nova.helpers.default_rabbitmq_user" $context)
      "password" (include "nova.helpers.default_user_password" $context)
      "port" .Values.rabbitmq.port
      "virtual_host" .Values.rabbitmq.virtual_host
      "host" (default (printf "%s-rabbitmq" .Release.Name) .Values.rabbitmq.host)
    }}
  {{- include "utils.rabbitmq_url" (tuple . $data) }}
{{- end -}}

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
