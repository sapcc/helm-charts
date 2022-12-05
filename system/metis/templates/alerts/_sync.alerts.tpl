- name: replicationV2.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
{{- if $backup.sync_enabled }}
  - alert: Metis{{ $backup.name | camelcase }}SyncErrorsHigh
    expr: increase(metis_replication_restart_counter{pod=~"mariadb-sync-{{$backup.name}}-[a-z0-9]{8,10}-[a-z0-9]{3,6}"}[60m]) > 0
    for: 15m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
    annotations:
      description: The sync of mariadb-{{$backup.name}} restarts frequently
      summary: Database replication restarting frequently
  - alert: Metis{{ $backup.name | camelcase }}SyncIncomplete
    expr: sum(metis_sync_status{pod=~"mariadb-sync-{{$backup.name}}-[a-z0-9]{8,10}-[a-z0-9]{3,6}"}) != 3
    for: 30m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
    annotations:
      description: The sync for mariadb-{{$backup.name}} has not completed for >30 minutes
      summary: Database replication is incomplete
  - alert: Metis{{ $backup.name | camelcase }}NoRotation
    expr: (timestamp(metis_binlog_rotation_timestamp_seconds{kubernetes_pod_name=~"mariadb-sync-{{ $backup.name }}-[a-z0-9]{8,10}-[a-z0-9]{3,6}"}) - metis_binlog_rotation_timestamp_seconds{kubernetes_pod_name=~"mariadb-sync-{{ $backup.name }}-[a-z0-9]{8,10}-[a-z0-9]{3,6}"}) / 60 > 1440
    for: 15m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
    annotations:
      description: The there was no binlog rotation event for mariadb-{{$backup.name}} for over 1d
      summary: Binlog rotation not registered correctly
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
