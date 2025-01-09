- name: pxc-backup.alerts
  rules:
  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBackupNotSucceeded
    expr: (kube_customresource_perconaxtradbclusterbackup_status{app_kubernetes_io_instance="{{ include "pxc-db.clusterName" . }}",state="Succeeded"} != 1)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/database/db_pxc_state_alerts#GaleraClusterBackupNotSucceeded'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} cluster backup is not succeeded."
      summary: "{{ include "pxc-db.fullname" . }} cluster backup is not succeeded."

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBackupMissing
    expr: (time() - max by (app_kubernetes_io_instance) (kube_customresource_perconaxtradbclusterbackup_completed{app_kubernetes_io_instance="{{ include "pxc-db.clusterName" . }}"}) > 129600)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/database/db_pxc_state_alerts#GaleraClusterBackupMissing'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} cluster has no new full backups completed earlier than 36 hours ago."
      summary: "{{ include "pxc-db.fullname" . }} cluster has no new full backups completed earlier than 36 hours ago."

{{- if .Values.backup.pitr.enabled }}
  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBinlogProcessingTooOld
    expr: (time() - pxc_binlog_collector_last_processing_timestamp{app_kubernetes_io_instance="{{ include "pxc-db.clusterName" . }}"} > 1800)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/database/db_pxc_state_alerts#GaleraClusterBinlogProcessingTooOld'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "More than 30 minutes passed since the last cluster {{ include "pxc-db.fullname" . }} binlog processing."
      summary: "{{ include "pxc-db.fullname" . }} cluster binlog processing is too old."

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBinlogUploadTooOld
    expr: (time() - pxc_binlog_collector_last_upload_timestamp{app_kubernetes_io_instance="{{ include "pxc-db.clusterName" . }}"} > 1800)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/database/db_pxc_state_alerts#GaleraClusterBinlogUploadTooOld'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "More than 30 minutes passed since the last cluster {{ include "pxc-db.fullname" . }} binlog upload."
      summary: "{{ include "pxc-db.fullname" . }} cluster binlog upload is too old."
{{- end }}
