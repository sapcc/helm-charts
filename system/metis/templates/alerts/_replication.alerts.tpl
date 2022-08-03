- name: replication.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
  - alert: {{$backup.name}}ReplicationErrorsHigh
    expr: increase(maria_backup_errors{app_kubernetes_io_instance=~"mariadb-replication-{{$backup.name}}-metis"}[15m]) > 2
    for: 15m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.alerts.tier }}
    annotations:
      description: The replication for mariadb-replication-{{$backup.name}}-metis restarts frequently
      summary: Database replication restarting frequently
  - alert: {{$backup.name}}ReplicationMissing
    expr: maria_backup_status{kind="full_backup",kubernetes_pod_name=~"mariadb-replication-{{$backup.name}}.*"} == 0
    for: 30m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.alerts.tier }}
    annotations:
      description: The replication for mariadb-replication-{{$backup.name}}-metis has not completed for >30 minutes
      summary: Database replication is incomplete
{{- end }}
- name: metisstatus.alerts
  rules:
  - alert: MetisMetadataLocksIncreased
    expr: metis_metadata_locks > 0
    for: 15m
    labels:
      context: db
      service: metis
      severity: info
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.alerts.tier }}
    annotations:
      description: MetisDB has 1 or more metadata locks for >15m
      summary: MetisDB has metadata locks
