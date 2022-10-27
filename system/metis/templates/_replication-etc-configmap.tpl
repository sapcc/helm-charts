{{/*
Create the config map content for replication pod
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
  binlog_max_reconnect_attempts: {{ .common.binlog_max_reconnect_attempts }}
database:
  type: "mariadb"
  user: root
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
        dump_filter_buffer_size_mb: {{ .common.dump_filter_buffer_size_mb }}
{{- end -}}

{{/*
Create the config map content for sync pod
*/}}
{{- define "sync.configmap" -}}
region: {{ .root.Values.global.region }}
loglevel: "debug"
swiftBackup:
  service: "{{ .backup.name }}"
  container: "mariadb-backup-qa-de-1"
  creds:
    identityEndpoint:  "https://identity-3.{{ .root.Values.global.region }}.cloud.sap/v3"
    user: "db_backup"
    userDomain: "Default"
    project: "master"
    projectDomain: "ccadmin"
replication:
  sourceDB:
    host: "{{ .backup.name }}-mariadb.monsoon3"
    port: {{ .mariadb.port_public }}
    user: "root"
  targetDB:
    host: "{{ .mariadb.name }}-mariadb.metis"
    port: {{ .mariadb.port_public }}
    user: "root"
  schemas:
  {{- range $db := .backup.databases }}
    - "{{$db}}"
  {{- end }}
  serverID: 998
  binlogMaxReconnectAttempts: {{ .common.binlog_max_reconnect_attempts }}
{{- end -}}
