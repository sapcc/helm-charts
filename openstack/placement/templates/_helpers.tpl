{{- define "placement.job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $all := list (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" .) | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary "" $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set .imageVersion or similar"}}
  {{- end }}
{{- end }}

{{- define "placement.helpers.db_suffix" }}
  {{- if eq .Values.dbType "mariadb" }}
    {{- print "mariadb" }}
  {{- else if eq .Values.dbType "pxc-db" }}
    {{- print "db-haproxy" }}
  {{- else }}
    {{- fail (print "Unsupported database type in .Values.dbType") }}
  {{- end }}
{{- end }}

{{- define "placement.helpers.db_service_name" }}
  {{- $dbConfig := dict }}
  {{- if .Values.databaseOverride }}
    {{- $dbConfig = get .Values .Values.databaseOverride }}
    {{- if not $dbConfig }}
      {{- fail (printf "No database config found for override: %s, check your .Values.%s" .Values.databaseOverride .Values.databaseOverride) }}
    {{- end }}
  {{- else }}
    {{- if eq .Values.dbType "mariadb" }}
      {{- $dbConfig = .Values.mariadb }}
    {{- else if eq .Values.dbType "pxc-db" }}
      {{- $dbConfig = .Values.pxc_db }}
    {{- else }}
      {{- fail (print "Unsupported database type in .Values.dbType") }}
    {{- end }}
  {{- end }}
  {{- printf "%s-%s" $dbConfig.name (include "placement.helpers.db_suffix" .) -}}
{{- end }}

{{- define "placement.helpers.db_url" -}}
  {{- $dbConfig := dict }}
  {{- if .Values.databaseOverride }}
    {{- $dbConfig = get .Values .Values.databaseOverride }}
    {{- if not $dbConfig }}
      {{- fail (printf "No database config found for override: %s, check your .Values.%s" .Values.databaseOverride .Values.databaseOverride) }}
    {{- end }}
  {{- else }}
    {{- if eq .Values.dbType "mariadb" }}
      {{- $dbConfig = .Values.mariadb }}
    {{- else if eq .Values.dbType "pxc-db" }}
      {{- $dbConfig = .Values.pxc_db }}
    {{- else }}
      {{- fail (print "Unsupported database type in .Values.dbType") }}
    {{- end }}
  {{- end }}
  {{- $context := dict "target" $dbConfig.name "defaultUser" $dbConfig.defaultUser "users" $dbConfig.users }}
  {{- tuple . .Values.dbName (include "placement.helpers.default_db_user" $context) (include "placement.helpers.default_user_password" $context) $dbConfig.name .Values.dbType | include "utils.db_url" }}
{{- end }}

{{- /*
Helper function to fetch a value (e.g., password, name, user) from a user object in a users map.
Params:
  .target: the target (e.g., placement)
  .users: the users map
  .defaultUser: the defaultUser value
  .key: the key to fetch from the user object (e.g., "password", "name", "user")
*/ -}}
{{- define "placement.helpers.default_user_value" }}
  {{- $target := .target | lower }}
  {{- $users := .users }}
  {{- $defaultUser := .defaultUser }}
  {{- $key := .key }}
  {{- if not $users }}
    {{ fail (printf "No users map defined for target '%s'. Check your values for .users." $target) }}
  {{- end }}
  {{- if not $defaultUser }}
    {{ fail (printf "No defaultUser defined for target '%s'. Check your values for .defaultUser." $target) }}
  {{- end }}
  {{- $user := index $users $defaultUser }}
  {{- if not $user }}
    {{ fail (printf "No user '%s' found in users map for target '%s'. Check your .users for a key '%s'." $defaultUser $target $defaultUser) }}
  {{- end }}
  {{- if not (hasKey $user $key) }}
    {{ fail (printf "No key '%s' for user '%s' in users map for target '%s'. Check your .users['%s'] for a key '%s'." $key $defaultUser $target $defaultUser $key) }}
  {{- end }}
  {{- index $user $key }}
{{- end }}

{{- define "placement.helpers.default_user_password" }}
  {{- $params := dict "target" .target "users" .users "defaultUser" .defaultUser "key" "password" }}
  {{- include "placement.helpers.default_user_value" $params }}
{{- end }}

{{- define "placement.helpers.default_db_user" }}
  {{- $params := dict "target" .target "users" .users "defaultUser" .defaultUser "key" "name" }}
  {{- include "placement.helpers.default_user_value" $params }}
{{- end }}
