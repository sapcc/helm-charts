{{- if and .Values.backup_v2.alerts.enabled }}
- name: replication.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
{{- if not $backup.sync_enabled }}
  - alert: {{ $backup.name | camelcase }}ReplicationErrorsHigh
    expr: increase(maria_backup_errors{app_kubernetes_io_instance=~"mariadb-replication-{{$backup.name}}-metis"}[15m]) > 2
    for: 15m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
    annotations:
      description: The replication for mariadb-replication-{{$backup.name}}-metis restarts frequently
      summary: Database replication restarting frequently
  - alert: {{ $backup.name | camelcase }}ReplicationMissing
    expr: maria_backup_status{kind="full_backup",kubernetes_pod_name=~"mariadb-replication-{{$backup.name}}.*"} == 0
    for: 30m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
      playbook: "docs/operation/metis/metis/#database-replication-is-incomplete"
    annotations:
      description: The replication for mariadb-replication-{{$backup.name}}-metis has not completed for >30 minutes
      summary: Database replication is incomplete
{{- end }}
{{- end }}
  - alert: MetisMetadataLocksIncreased
    expr: metis_metadata_locks > 0
    for: 15m
    labels:
      context: db
      service: metis
      severity: info
      support_group: {{ required "$.Values.mariadb.alerts.support_group missing" $.Values.mariadb.alerts.support_group}}
    annotations:
      description: MetisDB has 1 or more metadata locks for >15m
      summary: MetisDB has metadata locks
{{- end }}
