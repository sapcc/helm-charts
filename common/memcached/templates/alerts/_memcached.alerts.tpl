groups:
- name: memcached.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MemcachedManyConnectionsThrottled
    expr: (rate(memcached_connections_yielded_total{app="{{ template "fullname" . }}"}[5m]) * 60) > 5
    for: 5m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: 'Many client connections throttled in memcache of {{`{{ $labels.app }}`}}.'
      summary: Many throttled client connections
