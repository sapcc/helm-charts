{{/* vim: set filetype=helm */}}

{{/*
Create a default fully qualified app name.
The limit is 63 chars as per RFC 1035, but we truncate to 48 chars to leave
some space for the name suffixes on replicasets and pods.
*/}}
{{- define "postgres.fullname" -}}
  {{- printf "%s-postgresql" .Release.Name | trunc 48 | replace "_" "-" -}}
{{- end -}}

{{- define "preferredRegistry" -}}
  {{- if .Values.useAlternateRegion -}}
    {{ .Values.global.registryAlternateRegion | required ".Values.global.registryAlternateRegion missing" -}}
  {{- else -}}
    {{ .Values.global.registry | required ".Values.global.registry missing" -}}
  {{- end -}}
{{- end -}}

{{- if .Values.postgresDatabase }}
{{- fail "postgres-ng: .Values.postgresDatabase is not supported anymore! Please use .Values.databases instead." }}
{{- end }}

{{- if .Values.postgresPassword }}
{{- fail "postgres-ng: Setting the password via postgresPassword is no longer supported as it is auto generated on each start. Please remove the value and any vault references!" }}
{{- end }}

{{- if .Values.postgresUser }}
{{- fail "postgres-ng: Changing the superuser away from postgres is no longer supported as it is required for updates. Please create extra users via the users value." }}
{{- end }}

{{- if lt ($.Values.postgresVersion | int) 15 }}
{{- fail "postgres-ng: only postgres version 15 and up are supported by this chart version" }}
{{- end }}

{{- if .Values.tableOwner }}
{{- fail "postgres-ng: .Values.tableOwner is not supported anymore! Please set .Values.databases[name].owner instead." }}
{{- end }}

{{- if eq (len .Values.databases) 0 }}
  {{- fail "postgres-ng: need at least one entry in .Values.databases" }}
{{- end }}

{{- range $db := sortAlpha (keys .Values.databases) }}
  {{- if (contains "_" $db) }}
    {{- fail (printf "postgres-ng: Database name %q may not contain underscores!" $db) }}
  {{- end }}
  {{- if eq $db "postgres" "template0" "template1" }}
    {{- fail (printf "postgres-ng: Database name %q cannot be used because this name is reserved for an internal database!" $db) }}
  {{- end }}

  {{- $cfg := index $.Values.databases $db }}
  {{- if not $cfg.owner }}
    {{- fail (printf "postgres-ng: Missing owner name for database %q" $db) }}
  {{- else if not (hasKey $.Values.users $cfg.owner) }}
    {{- fail (printf "postgres-ng: Invalid owner name for database %q (user %q is not declared in .Values.users)" $db $cfg.owner) }}
  {{- end }}
{{- end }}

{{- if eq (len .Values.users) 0 }}
  {{- fail "postgres-ng: need at least one entry in .Values.users" }}
{{- end }}

{{- range $user := sortAlpha (keys .Values.users) }}
  {{- if eq $user "backup" "metrics" "postgres" }}
    {{- fail (printf "postgres-ng: User %q cannot be declared in .Values.users explicitly!" $db) }}
  {{- end }}

  {{- $cfg := index $.Values.users $db }}
  {{- range $grant := $cfg.grant | default (list) }}
    {{- if $grant | contains "%PGDATABASE%" }}
      {{- fail "postgres-ng: .Values.users[].grant[] may not contain %PGDATABASE anymore! Please name the database explicitly." }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if (hasKey .Values "sqlOnCreate") }}
{{- fail "postgres-ng: .Values.sqlOnCreate was removed because we are not aware of users (if you need it, please get in touch with us" }}
{{- end }}
{{- if (hasKey .Values "sqlOnStartup") }}
{{- fail "postgres-ng: .Values.sqlOnStartup was removed because we are not aware of users (if you need it, please get in touch with us" }}
{{- end }}
