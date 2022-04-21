{{/*
Create the config map content
*/}}
{{- define "replication.configmap" -}}
namespace: {{ .root.Release.Namespace }}
service_name: {{ .backup.name }}
sidecar: false
backup:
  full_backup_cron_schedule: {{ .common.full_backup_cron_schedule }}
  incremental_backup_in_minutes: {{ .common.incremental_backup_in_minutes }}
  backup_dir: {{ .common.backup_dir }}
  enable_init_restore: false
  disable_binlog_purge_on_rotate: true
database:
  type: "mariadb"
  user: root
  password: {{ .backup.root_password }}
  host: {{ .backup.name }}-mariadb.{{ .backup.namespace }}
  port: 3306
  server_id: 998
  data_dir: /var/lib/mysql
  log_name_format: mysqld-bin
  binlog_max_reconnect_attempts: {{.common.binlogMaxReconnectAttempts}}
  databases:
  {{- range $db := .backup.databases }}
    - "{{$db}}"
  {{- end }}
storages:
  maria_db:
    -   name: metis
        host: {{ .mariadb.name }}-mariadb
        port: {{ .mariadb.port_public }}
        user: root
        password: {{ .mariadb.root_password }}
        parse_schema: {{ .backup.parse_schema }}
        databases:
        {{- range $db := .backup.databases }}
          - "{{$db}}"
        {{- end }}
{{- end -}}
