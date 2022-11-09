- name: replicationV2.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
{{- if $backup.sync_enabled }}
  - alert: {{ $backup.name | camelcase }}SyncErrorsHigh
    expr: increase(metis_replication_restart_counter{pod=~"mariadb-sync-{{$backup.name}}.*"}[15m]) > 2
    for: 15m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
      tier: {{ required "$.Values.alerts.tier missing" $.Values.alerts.tier }}
    annotations:
      description: The sync of mariadb-{{$backup.name}} restarts frequently
      summary: Database replication restarting frequently
  - alert: {{ $backup.name | camelcase }}SyncIncomplete
    expr: sum(metis_sync_status{pod=~"mariadb-sync-{{$backup.name}}.*"}) != 3
    for: 30m
    labels:
      context: replicationerrors
      service: "metis"
      severity: info
      support_group: {{ required "$.Values.backup_v2.alerts.supportGroup missing" $.Values.backup_v2.alerts.supportGroup}}
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.alerts.tier }}
    annotations:
      description: The sync for mariadb-{{$backup.name}} has not completed for >30 minutes
      summary: Database replication is incomplete
{{- end }}
{{- end }}
