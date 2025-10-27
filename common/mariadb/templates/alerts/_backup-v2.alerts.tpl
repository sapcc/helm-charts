- name: backup-v2.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDatabaseFullBackupMissing
    expr: maria_backup_status{kind="full_backup", app_kubernetes_io_instance=~"{{ include "fullName" . }}" } != 1
    for: 4h
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "fullName" . }} full backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} full backup missing

  - alert: {{ include "alerts.service" . | title }}MariaDatabaseIncBackupMissing
    expr: maria_backup_status{kind="inc_backup", app_kubernetes_io_instance=~"{{ include "fullName" . }}" } != 1
    for: {{ mul .Values.backup_v2.incremental_backup_in_minutes 5 }}m
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "fullName" . }} incremental backup missing. Please check the backup container.
      summary: {{ include "fullName" . }} incremental backup missing

{{- if .Values.backup_v2.verification.enabled }}
  - alert: {{ include "alerts.service" . | title }}MariaDatabaseBackupVerificationFailed
    expr: sum(maria_backup_verify_status{app_kubernetes_io_instance=~"{{ include "fullName" . }}" }) < 1
    for: 16h
    labels:
      context: "{{ .Release.Name }}"
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: All {{ include "fullName" . }} backup verifications failed for both storage backends. Check the backup container.
      summary: {{ include "fullName" . }} backup failed all verifications
{{- end }}
