- name: backup.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDatabaseBackupMissing
    expr: absent(backup_last_success{app=~"{{ include "fullName" . }}"})
    for: 1h
    labels:
      context: backupage
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseBackupAge2Hours
    expr: floor((time() - backup_last_success{app=~"{{ include "fullName" . }}"}) / 60 / 60) >= 1
    for: 1h
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

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseBackupAge4Hours
    expr: floor((time() - backup_last_success{app=~"{{ include "fullName" . }}"}) / 60 / 60) >= 3
    for: 1h
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
