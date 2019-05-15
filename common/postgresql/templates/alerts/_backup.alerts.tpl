groups:
- name: backup.alerts
  rules:
  - alert: OpenstackDatabaseBackupMissing
    expr: absent(backup_last_success{app=~"{{ template "fullname" . }}"})
    for: 1h
    labels:
      context: backupage
      dashboard: db-backup
      service: {{ template "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ template "fullname" . }} Backup missing. Please check backup container.
      summary: {{ template "fullname" . }} Backup missing

  - alert: OpenstackDatabaseBackupAge2Hours
    expr: floor((time() - backup_last_success{app=~"{{ template "fullname" . }}"}) / 60 / 60) >= 2
    for: 10m
    labels:
      context: backupage
      dashboard: db-backup
      meta: "{{`{{ $labels.app }}`}}"
      service: {{ template "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: docs/support/playbook/db_backup_issues.html
    annotations:
      description: The last successful database backup for {{`{{ $labels.app }}`}} is {{`{{ $value }}`}} hours old.
      summary: Database Backup too old

  - alert: OpenstackDatabaseBackupAge4Hours
    expr: floor((time() - backup_last_success{app=~"{{ template "fullname" . }}"}) / 60 / 60) >= 4
    for: 10m
    labels:
      context: backupage
      dashboard: db-backup
      meta: "{{`{{ $labels.app }}`}}"
      service: {{ template "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: docs/support/playbook/db_backup_issues.html
    annotations:
      description: The last successful database backup for {{`{{ $labels.app }}`}} is {{`{{ $value }}`}} hours old.
      summary: Database Backup too old

  - alert: OpenstackDatabaseBackupReplicationFailure
    expr: backup_replication_last_run{kind="success", app=~"{{ template "fullname" . }}"} == 0
    for: 24h
    labels:
      context: replicationage
      dashboard: db-backup-replication
      meta: "{{`{{ $labels.source_region }}`}} > {{`{{ $labels.region }}`}}"
      service: {{ template "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: Database backup failed to replicate from {{`{{ $labels.source_region }}`}} to {{`{{ $labels.region }}`}}.
      summary: Database Backup Replication Failed in {{`{{ $labels.region }}`}}
