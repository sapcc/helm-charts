- name: backup-v2.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDatabaseFullBackupMissing
    expr: maria_backup_status{kind="full_backup", release={{ include "alerts.service" . | quote }} } != 1
    for: 4h
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} full backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} full backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseIncBackupMissing
    expr: maria_backup_status{kind="inc_backup", release={{ include "alerts.service" . | quote }} } != 1
    for: {{ mul .Values.backup_v2.incremental_backup_in_minutes 5 }}m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} incremental backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} incremental backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseBackupVerifyChecksumFailed
    expr: maria_backup_verify_status{kind="verify_checksum", service=~"{{  include "alerts.service" . }}.*", storage=~"swift.*" } != 1
    for: 12h
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} backup checksum verification from Swift failed. Please check the backup container.
      summary: {{ include "fullName" . }} backup checksum failed to verify
