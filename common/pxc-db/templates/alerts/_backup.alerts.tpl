- name: pxc-backup.alerts
  rules:
  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBackupNotSucceeded
    expr: (kube_customresource_perconaxtradbclusterbackup_status{app_kubernetes_io_instance="{{ include "pxc-db.fullname" . }}",state="Succeeded"} != 1)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} cluster backup is not succeeded."
      summary: "{{ include "pxc-db.fullname" . }} cluster backup is not succeeded."

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterBackupMissing
    expr: (time() - max by (app_kubernetes_io_instance) (kube_customresource_perconaxtradbclusterbackup_completed{app_kubernetes_io_instance="{{ include "pxc-db.fullname" . }}") > 129600)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} cluster has no new backups completed earlier than 36 hours ago."
      summary: "{{ include "pxc-db.fullname" . }} cluster has no new backups completed earlier than 36 hours ago."
