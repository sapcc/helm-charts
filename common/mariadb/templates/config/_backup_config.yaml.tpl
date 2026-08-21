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
  user: {{ include "mariadb.resolve_secret_squote" .Values.users.backup.name | required ".Values.users.backup.name is required" }}
  version: {{ .Values.backup_v2.maria_db.version }}
  password: {{ include "mariadb.resolve_secret_squote" .Values.users.backup.password | required ".Values.users.backup.password is required" }}
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
  {{- $cephTargets := list }}
  {{- if .Values.backup_v2.ceph_s3.enabled }}
    {{- $cephTargets = default (list) (dig "mariadb" "backup_v2" "ceph_s3" "targets" (list) .Values.global) }}
    {{- if eq (len $cephTargets) 0 }}
      {{- fail "backup_v2.ceph_s3.enabled is true but global.mariadb.backup_v2.ceph_s3.targets is empty" }}
    {{- end }}
    {{- $names := list }}
    {{- range $t := $cephTargets }}
      {{- $r := default $.Values.global.region $t.region }}
      {{- $names = append $names (default (printf "ceph-%s" $r) $t.name) }}
    {{- end }}
    {{- if ne (len $names) (len (uniq $names)) }}
      {{- fail (printf "duplicate ceph_s3 target name(s) in %v — please change 'name' to be unique" $names) }}
    {{- end }}
  {{- end }}
  {{- if or .Values.backup_v2.aws.enabled (gt (len $cephTargets) 0) }}
  s3:
    {{- if .Values.backup_v2.aws.enabled }}
    - name: aws-{{ .Values.global.mariadb.backup_v2.aws.region }}
      aws_access_key_id: {{ include "mariadb.resolve_secret_squote" .Values.global.backup_v2.aws_access_key_id }}
      aws_secret_access_key: {{ include "mariadb.resolve_secret_squote" .Values.global.backup_v2.aws_secret_access_key }}
      region: {{ .Values.global.mariadb.backup_v2.aws.region }}
      bucket_name: "mariadb-backup-{{ .Values.global.region }}"
      sse_customer_algorithm: "AES256"
      sse_customer_key: {{ include "mariadb.resolve_secret_squote" .Values.global.mariadb.backup_v2.aws.sse_customer_key }}
      {{- $awsOverride := dig "mariadb" "backup_v2" "aws" "object_lock" (dict) .Values.global }}
      {{- $awsObjectLock := include "mariadb.backup_v2.object_lock" (dict "target" $awsOverride "default" .Values.backup_v2.object_lock) }}
      {{- if $awsObjectLock }}
      {{- $awsObjectLock | nindent 6 }}
      {{- end }}
    {{- end }}
    {{- range $t := $cephTargets }}
    {{- $region := default $.Values.global.region $t.region }}
    - name: {{ default (printf "ceph-%s" $region) $t.name }}
      aws_access_key_id: {{ include "mariadb.resolve_secret_squote" (required "ceph_s3 target requires aws_access_key_id" $t.aws_access_key_id) }}
      aws_secret_access_key: {{ include "mariadb.resolve_secret_squote" (required "ceph_s3 target requires aws_secret_access_key" $t.aws_secret_access_key) }}
      aws_endpoint: {{ required "ceph_s3 target requires endpoint" $t.endpoint | quote }}
      s3_force_path_style: {{ if hasKey $t "force_path_style" }}{{ $t.force_path_style }}{{ else }}{{ $.Values.backup_v2.ceph_s3.force_path_style }}{{ end }}
      region: {{ $region }}
      bucket_name: {{ $t.bucket_name | default (printf "mariadb-backup-%s" $.Values.global.region) | quote }}
      {{- if ternary $t.verify $.Values.backup_v2.ceph_s3.verify (hasKey $t "verify") }}
      verify: true
      {{- end }}
      {{- $cephSseDefault := dig "mariadb" "backup_v2" "ceph_s3" "sse_customer_key" "" $.Values.global }}
      {{- $cephSseC := include "mariadb.backup_v2.sse_c" (dict "target" $t "default" $cephSseDefault) }}
      {{- if $cephSseC }}
      {{- $cephSseC | nindent 6 }}
      {{- end }}
      {{- $cephObjectLock := include "mariadb.backup_v2.object_lock" (dict "target" $t.object_lock "default" $.Values.backup_v2.object_lock) }}
      {{- if $cephObjectLock }}
      {{- $cephObjectLock | nindent 6 }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if .Values.backup_v2.swift.enabled }}
  swift:
    - name: swift-{{ .Values.global.region }}
      auth_version: {{ .Values.backup_v2.swift.auth_version }}
      auth_url: "https://identity-3.{{ .Values.global.region }}.cloud.sap/v3"
      user_name: {{ .Values.backup_v2.swift.user_name }}
      user_domain_name: {{ .Values.backup_v2.swift.user_domain_name }}
      project_name: {{ .Values.backup_v2.swift.project_name }}
      project_domain_name: {{ .Values.backup_v2.swift.project_domain_name }}
      password: {{ include "mariadb.resolve_secret_squote" .Values.backup_v2.swift.password | required "Please set .Values.backup_v2.swift.password" }}
      region: {{ .Values.global.region }}
      container_name: "mariadb-backup-{{ .Values.global.region }}"
  {{- end }}
verification:
  run_after_inc_backups: {{ .Values.backup_v2.verification.run_after_inc_backups }}
