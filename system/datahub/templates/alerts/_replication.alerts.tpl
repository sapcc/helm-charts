- name: replication.alerts
  rules:
{{- range $backup := .Values.backup_v2.backups }}
  - alert: {{$backup.name}}ReplicationErrorsHigh
    expr: maria_backup_errors{app_kubernetes_io_instance=~"{{$backup.name}}-mariadb-replication-datahub"} > 6
    for: 15m
    labels: replicationerrors
    service: "datahub-mariadb-replication"
    severity: info
    tier: {{ required "$.Values.backup_v2.alerts.tier missing" $.Values.backup_v2.alerts.tier }}
{{- end }}