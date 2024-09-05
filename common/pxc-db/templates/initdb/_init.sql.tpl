SET character_set_server = '{{ .Values.character_set_server }}';
SET collation_server = '{{ .Values.collation_server }}';
SET sql_mode = CONCAT(@@sql_mode, ',NO_BACKSLASH_ESCAPES');
{{- $dbs := coalesce .Values.databases (list .Values.name) }}
{{- range $dbs }}
CREATE DATABASE IF NOT EXISTS {{ . }};
{{- end }}

{{- if and .Values.global.dbUser .Values.global.dbPassword (not (hasKey .Values.users (default "" .Values.global.dbUser))) (not .Values.custom_initdb_secret) }}
CREATE DATABASE IF NOT EXISTS `{{ .Values.name }}`;
CREATE USER IF NOT EXISTS {{ .Values.global.dbUser }};
GRANT ALL PRIVILEGES ON `{{ .Values.name }}.*`
  TO {{ include "pxc-db.resolve_secret_squote" (.Values.global.dbUser) }}
  IDENTIFIED BY {{ include "pxc-db.resolve_secret_squote" .Values.global.dbPassword }};
{{- end }}

{{- range $username, $values := .Values.users }}
    {{- $username := default $username $values.name }}
    {{- if not $values.password }}
-- Skipping user {{ $username }} without password
    {{- else }}
CREATE USER IF NOT EXISTS {{ include "pxc-db.resolve_secret_squote" $username }};
ALTER USER {{ include "pxc-db.resolve_secret_squote" $username }} IDENTIFIED BY {{ include "pxc-db.resolve_secret_squote" $values.password }}
{{- if $values.limits }}
  WITH
{{- range $k, $v := $values.limits }}
    {{ $k | upper }} {{ $v }}
{{- end }}
{{- end }};
        {{- range $values.grants }}
GRANT {{ . }} TO {{ include "pxc-db.resolve_secret_squote" $username }};
        {{- end }}
    {{- end }}
{{- end }}

{{- if (and (hasKey .Values "ccroot_user") (.Values.ccroot_user.enabled)) }}
CREATE USER IF NOT EXISTS 'ccroot'@'127.0.0.1';
GRANT ALL PRIVILEGES ON *.* TO 'ccroot'@'127.0.0.1';
{{- else }}
DROP USER IF EXISTS 'ccroot'@'127.0.0.1';
{{- end }}

FLUSH PRIVILEGES;
