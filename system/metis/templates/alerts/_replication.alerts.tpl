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
      tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.backup_v2.alerts.tier }}
    annotations:
      description: The replication for mariadb-replication-{{$backup.name}}-metis restarts frequently
      summary: Database replication restarting frequently
{{- end }}
