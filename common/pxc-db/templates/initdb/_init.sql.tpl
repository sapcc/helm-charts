SET character_set_server = '{{ .Values.job.initdb.character_set_server }}';
SET collation_server = '{{ .Values.job.initdb.collation_server }}';
SET sql_mode = CONCAT(@@sql_mode, ',NO_BACKSLASH_ESCAPES');
{{- $dbs := coalesce .Values.databases (list .Values.name) }}
{{- range $dbs }}
CREATE DATABASE IF NOT EXISTS {{ . }};
{{- end }}

{{- range $username, $values := .Values.users }}
    {{- $username := default $username $values.name }}
    {{- if not $values.password }}
-- Skipping user {{ $username }} without password
    {{- else }}
CREATE USER IF NOT EXISTS {{ include "pxc-db.resolve_secret_squote" $username }};
{{- if $values.limits }}
ALTER USER {{ include "pxc-db.resolve_secret_squote" $username }}
  WITH
{{- range $k, $v := $values.limits }}
    {{ $k | upper }} {{ $v }}
{{- end }};
{{- end }}
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
