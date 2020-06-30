groups:
- name: pg-database.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}PostgresDatabaseTooLarge
    expr: max(pg_database_size_bytes{datname="{{ default .Release.Name .Values.db_name }}",app!~"sentry-postgresql"}) by (app,datname) >= 8.589934592e+09
    for: 5m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: 'The size of the database {{`{{ $labels.datname }}`}} exceeds 8 GiB : {{`{{ $value }}`}} bytes.'
      summary: Postgres database too large.

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
