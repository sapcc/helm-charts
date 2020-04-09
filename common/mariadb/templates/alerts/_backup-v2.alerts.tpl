- name: backup-v2.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDatabaseFullBackupMissing
    expr: count(maria_backup_status{kind="full_backup"} == 0) by (release) == 0
    for: 15m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} full backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} full backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseIncBackupMissing
    expr: count(maria_backup_status{kind="inc_backup"} == 0) by (release) == 0
    for: {{ .Values.backup_v2.incremental_backup_in_minutes}}m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} incremental backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} incremental backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseFullBackupStorageError
    expr: count(maria_backup_status{kind="full_backup"} == 0) by (release, storage)
    for: 15m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} full backup storage error. Please check the backup container.
      summary: {{ include "fullName" . }} backup storage error

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseIncBackupStorageError
    expr: count(maria_backup_status{kind="inc_backup"} == 0) by (release, storage)
    for: {{ .Values.backup_v2.incremental_backup_in_minutes}}m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} incremental backup storage error. Please check the backup container.
      summary: {{ include "fullName" . }} incremental backup storage error
