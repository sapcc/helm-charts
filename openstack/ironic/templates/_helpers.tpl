{{- define "ironic.helpers.extra_specs" }}
{{- $envAll := index . 0 }}
{{- $key :=  index . 1 }}
{{- $extraSpecs := get $envAll.Values.flavors.extra_specs $key | required (print "Please set ironic.flavors.extra_specs." $key) }}
{{- if ge (len .) 3 }}
    {{- $override := index . 2 }}
    {{- $extraSpecs = merge $override $extraSpecs }}
{{- end }}
{{- range $k, $v := $extraSpecs }}
{{ $k | quote }}: {{ $v | quote }}
{{- end }}
{{- end }}

{{- define "ironic.service_dependencies" }}
{{- include "ironic.db_service" . }},{{ include "ironic.rabbitmq_service" . -}}
{{- end }}

{{- define "ironic.db_service" }}
{{- include "utils.db_host" . }}
{{- end }}

{{- define "ironic.rabbitmq_service" -}}
ironic-rabbitmq
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $all := list
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary "" $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set ironic.imageVersion" }}
  {{- end }}
{{- end }}

{{- /*
Helper function to fetch a value (e.g., password, name, user) from a user object in a users map.
Params:
  .valueName: values map name to help print better error messages
  .usersMap: a map containing .users and .defaultUser
  .key: the key to fetch from the user object (e.g., "password", "name", "user")
*/ -}}
{{- define "ironic.helpers.default_user_value" -}}
  {{- $valueName := .valueName }}
  {{- $usersMap := .usersMap | required (printf "Missing %s" $valueName) }}
  {{- $key := .key }}
  {{- $users := $usersMap.users | required (printf "Missing %s.users" $valueName) }}
  {{- $defaultUserKey := $usersMap.defaultUser | required (printf "Missing %s.defaultUser" $valueName) }}
  {{- $user := index $users $defaultUserKey | required (printf "Missing entry for %s in %s.users" $defaultUserKey $valueName) }}
  {{- index $user $key | required (printf "No key '%s' in '%s.users.%s'." $key $valueName $defaultUserKey) }}
{{- end }}

{{- define "ironic.helpers.service_user_username" -}}
{{- $params := dict "valueName" "service_users" "usersMap" .Values.service_users "key" "username" }}
{{- include "ironic.helpers.default_user_value" $params }}
{{- end }}

{{- define "ironic.helpers.service_user_password" -}}
{{- $params := dict "valueName" "service_users" "usersMap" .Values.service_users "key" "password" }}
{{- include "ironic.helpers.default_user_value" $params }}
{{- end }}
