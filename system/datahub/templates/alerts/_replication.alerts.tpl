- name: replication.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
  - alert: {{$backup.name}}ReplicationErrorsHigh
    expr: maria_backup_errors{app_kubernetes_io_instance=~"{{$backup.name}}-mariadb-replication-datahub"} > 6
    for: 15m
    labels: 
      context: replicationerrors
      service: "datahubdb"
      severity: info
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.backup_v2.alerts.tier }}
    annotations:
      description: The replication for{{$backup.name}}-mariadb-replication-datahub restarts frequently
      summary: Database replication restarting frequently
{{- end }}