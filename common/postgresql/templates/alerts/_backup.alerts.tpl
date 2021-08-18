groups:
- name: backup.alerts
  rules:
  - alert: {{ include "alerts.name_prefix" . }}PostgresDatabaseBackupMissing
    expr: absent(backup_last_success{app=~"{{ template "fullname" . }}"})
    for: 1h
    labels:
      context: backupage
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ template "fullname" . }} Backup missing. Please check backup container.
      summary: {{ template "fullname" . }} Backup missing

  - alert: {{ include "alerts.name_prefix" . }}PostgresDatabaseBackupAge2Hours
    expr: floor((time() - backup_last_success{app=~"{{ template "fullname" . }}"}) / 60 / 60) >= 2
    for: 10m
    labels:
      context: backupage
      meta: "{{`{{ $labels.app }}`}}"
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: docs/support/playbook/db_backup_issues.html
    annotations:
      description: The last successful database backup for {{`{{ $labels.app }}`}} is {{`{{ $value }}`}} hours old.
      summary: Database Backup too old

  - alert: {{ include "alerts.name_prefix" . }}PostgresDatabaseBackupAge4Hours
    expr: floor((time() - backup_last_success{app=~"{{ template "fullname" . }}"}) / 60 / 60) >= 4
    for: 10m
    labels:
      context: backupage
      meta: "{{`{{ $labels.app }}`}}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: docs/support/playbook/db_backup_issues.html
    annotations:
      description: The last successful database backup for {{`{{ $labels.app }}`}} is {{`{{ $value }}`}} hours old.
      summary: Database Backup too old
