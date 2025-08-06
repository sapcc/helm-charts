SET character_set_server = '{{ .Values.character_set_server }}';
SET collation_server = '{{ .Values.collation_server }}';
SET sql_mode = CONCAT(@@sql_mode, ',NO_BACKSLASH_ESCAPES');
{{- $dbs := coalesce .Values.databases (list .Values.name) }}
{{- range $dbs }}
CREATE DATABASE IF NOT EXISTS {{ . }};
{{- end }}

{{- if and .Values.global.dbUser .Values.global.dbPassword (not (hasKey .Values.users (default "" .Values.global.dbUser))) }}
CREATE USER IF NOT EXISTS {{ .Values.global.dbUser }};
GRANT ALL PRIVILEGES ON {{ .Values.name }}.*
  TO {{ include "mariadb.resolve_secret_squote" (.Values.global.dbUser) }}
  IDENTIFIED BY {{ include "mariadb.resolve_secret_squote" .Values.global.dbPassword }};
{{- end }}

{{- range $username, $values := .Values.users }}
    {{- $username := default $username $values.name }}
    {{- if (and (hasKey $values "enabled") (eq (typeOf $values.enabled) "bool") (eq $values.enabled false)) }}
-- Dropping user {{ $username }} as it is disabled
DROP USER IF EXISTS {{ include "mariadb.resolve_secret_squote" $username }}@'%';
--
    {{- else if not $values.password }}
-- Skipping user {{ $username }} without password
    {{- else }}
DROP USER IF EXISTS {{ include "mariadb.resolve_secret_squote" $username }}@'localhost';
CREATE USER IF NOT EXISTS {{ include "mariadb.resolve_secret_squote" $username }}@'%';
ALTER USER {{ include "mariadb.resolve_secret_squote" $username }} IDENTIFIED BY {{ include "mariadb.resolve_secret_squote" $values.password }}
{{- if $values.limits }}
  WITH
{{- range $k, $v := $values.limits }}
    {{ $k | upper }} {{ $v }}
{{- end }}
{{- end }};
        {{- range $values.grants }}
GRANT {{ . }} TO {{ include "mariadb.resolve_secret_squote" $username }};
        {{- end }}
    {{- end }}
{{- end }}

ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;
ALTER USER 'root'@'%' IDENTIFIED BY {{ include "mariadb.resolve_secret_squote" .Values.root_password }};

{{- if .Values.metrics.enabled }}
CREATE USER IF NOT EXISTS 'monitor'@'127.0.0.1' WITH MAX_USER_CONNECTIONS 5;
GRANT SLAVE MONITOR, PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'monitor'@'127.0.0.1';
{{- else }}
DROP USER IF EXISTS 'monitor'@'127.0.0.1';
{{- end }}

{{- if (and (hasKey .Values "ccroot_user") (.Values.ccroot_user.enabled)) }}
CREATE USER IF NOT EXISTS 'ccroot'@'127.0.0.1';
GRANT ALL PRIVILEGES ON *.* TO 'ccroot'@'127.0.0.1';
{{- else }}
DROP USER IF EXISTS 'ccroot'@'127.0.0.1';
{{- end }}

FLUSH PRIVILEGES;
