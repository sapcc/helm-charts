namespace: {{ .Release.Namespace }}
service_name: {{ .Values.name }}
sidecar: false
backup:
  full_backup_cron_schedule: {{ .Values.backup_v2.full_backup_cron_schedule }}
  incremental_backup_in_minutes: {{ .Values.backup_v2.incremental_backup_in_minutes }}
  purge_binlog_after_minutes: {{ .Values.backup_v2.purge_binlog_after_minutes }}
  backup_dir: {{ .Values.backup_v2.backup_dir }}
  enable_init_restore: {{ .Values.backup_v2.enable_init_restore }}
  oauth:
    middleware: {{ .Values.backup_v2.oauth.middleware}}
    sap_id: {{ default false .Values.backup_v2.oauth.sap_id}}
    provider_url: "https://auth.mariabackup.{{ .Values.global.region }}.cloud.sap"
    redirect_url: "https://{{ .Values.name }}.mariabackup.{{ .Values.global.region }}.cloud.sap"
database:
  type: "mariadb"
  user: {{ .Values.users.backup.name | required ".Values.users.backup.name is required" }}
  version: {{ .Values.backup_v2.maria_db.version }}
  password: {{ .Values.users.backup.password | required ".Values.users.backup.password is required" }}
  host: {{ include "fullName" . }}
  port: 3306
  server_id: 999
  data_dir: /var/lib/mysql
  log_name_format: mysqld-bin
  databases:
  {{- range $db := coalesce .Values.backup_v2.databases .Values.databases (list .Values.name) }}
    - "{{$db}}"
  {{- end }}
  verify_tables:
  {{- range $tl := .Values.backup_v2.verify_tables }}
    - "{{$tl}}"
  {{- end }}
storages:
  s3:
    - name: aws-{{ .Values.global.mariadb.backup_v2.aws.region }}
      aws_access_key_id: {{ .Values.global.backup_v2.aws_access_key_id }}
      aws_secret_access_key: {{ .Values.global.backup_v2.aws_secret_access_key }}
      region: {{ .Values.global.mariadb.backup_v2.aws.region }}
      bucket_name: "mariadb-backup-{{ .Values.global.region }}"
      sse_customer_algorithm: "AES256"
      sse_customer_key: "{{ .Values.global.mariadb.backup_v2.aws.sse_customer_key }}"
  swift:
    - name: swift-{{ .Values.global.region }}
      auth_version: 3
      auth_url: "https://identity-3.{{ .Values.global.region }}.cloud.sap/v3"
      user_name: db_backup
      user_domain_name: Default
      project_name: master
      project_domain_name: ccadmin
      password: {{ .Values.backup_v2.swift.password | required "Please set .Values.backup_v2.swift.password" }}
      region: {{ .Values.global.region }}
      container_name: "mariadb-backup-{{ .Values.global.region }}"
verification:
  run_after_inc_backups: {{ .Values.backup_v2.verification.run_after_inc_backups }}
