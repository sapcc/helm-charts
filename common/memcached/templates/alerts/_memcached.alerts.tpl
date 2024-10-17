groups:
- name: memcached.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MemcachedManyConnectionsThrottled
    expr: (rate(memcached_connections_yielded_total{app_kubernetes_io_instance="{{ template "fullname" . }}"}[5m]) * 60) > {{ .Values.alerts.yielded_connections_threshold }}
    for: 5m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: 'Many client connections throttled in memcache of {{`{{ $labels.app_kubernetes_io_instance }}`}}.'
      summary: Many throttled client connections
