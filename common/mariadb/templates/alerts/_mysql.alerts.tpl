- name: mysql.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDBTooManyConnections
    expr: (mysql_global_variables_max_connections{app=~"{{ include "fullName" . }}"} - mysql_global_status_threads_connected{app=~"{{ include "fullName" . }}"} < 200)
    for: 30m
    labels:
      context: datbase
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} has too many connections open. Please check the service containers.
      summary: {{ include "fullName" . }} has too many connections open.

  - alert: {{ include "alerts.service" . | title }}MariaDBSlowQueries
    expr: (rate(mysql_global_status_slow_queries{app=~"{{ include "fullName" . }}"}[5m]) > 0)
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} has reported slow queries. Please check the DB.
      summary: {{ include "fullName" . }} reports slow queries.

  - alert: {{ include "alerts.service" . | title }}MariaDBWaitingForLock
    expr: (mysql_info_schema_threads_seconds{app=~"{{ include "fullName" . }},state=~"waiting for lock"} / 1000  > 15)
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: {{ include "fullName" . }} has queries waiting for lock more than 15 sec. Deadlock possible.
      summary: {{ include "fullName" . }} has queries waiting for lock.
