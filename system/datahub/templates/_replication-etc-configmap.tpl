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
  enable_init_restore: {{ .common.enable_init_restore }}
database:
  type: "mariadb"
  user: root
  version: {{ .backup.maria_db.version }}
  password: {{ .backup.root_password }}
  host: {{ .backup.name }}-mariadb.{{ .backup.namespace }}
  port: 3306
  server_id: 998
  data_dir: /var/lib/mysql
  log_name_format: mysqld-bin
  databases:
  {{- range $db := .backup.databases }}
    - "{{$db}}"
  {{- end }}
storages:
  maria_db:
    -   name: datahub
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