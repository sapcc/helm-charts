groups:
- name: pg-database.alerts
  rules:
  {{- if .Values.alerts.large_database_size_enabled }}
  - alert: {{ include "alerts.service" . | title }}PostgresDatabaseTooLarge
    expr: max(pg_database_size_bytes{datname="{{ default .Release.Name .Values.db_name }}"}) by (app,datname) >= 8.589934592e+09
    for: 5m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: 'The size of the database {{`{{ $labels.datname }}`}} exceeds 8 GiB : {{`{{ $value }}`}} bytes.'
      summary: Postgres database too large.
  {{- end }}

  - alert: {{ include "alerts.service" . | title }}PredictHighNumberOfDatabaseConnections
    expr: predict_linear(pg_stat_activity_count{datname="{{ default .Release.Name .Values.db_name }}"}[1h], 3*3600) >= 2000
    for: 5m
    labels:
      context: database
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service: {{ include "alerts.service" . }}
      severity: warning
      meta: "Predicting a high number of database connections for {{`{{ $labels.datname }}`}}"
    annotations:
      summary: High number of database connections
      description: Predicting more than 2000 database connections for {{ template "alerts.service" . }} within the next 3 hours and might be unavailable soon.

  - alert: {{ include "alerts.service" . | title }}StuckTransactions
    expr: max(pg_stat_activity_max_tx_duration{datname="{{ default .Release.Name .Values.db_name }}"}) > 300
    for: 5m
    labels:
      context: database
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service: {{ include "alerts.service" . }}
      severity: info
      meta: DB transactions are stuck
    annotations:
      summary: DB transactions are stuck
      description: >
        Some transactions are taking unusually long to complete or not making progress at all. Check the logs of the
        Postgres container; this could be caused by file locks getting stuck. If you get the chance, investigate this
        with the OS and storage experts while it's happening. But don't delay for too long! The locks must be put back
        in order before the entire connection pool is exhausted, or else the DB may become completely unresponsive!
