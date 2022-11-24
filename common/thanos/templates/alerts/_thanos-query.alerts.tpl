groups:
- name: thanos-query.alerts
  rules:
    - alert: ThanosQueryGrpcErrorRate
      expr: rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable",name="prometheus", prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      for: 5m
      labels:
        context: thanos
        service: metrics
        support_group: observability
        severity: info
        meta: 'Thanos query is returning errors for Prometheus {{`{{ $labels.prometheus }}`}}'
      annotations:
        description: 'Thanos Query is returning Internal/Unavailable errors for Prometheus {{`{{ $labels.prometheus }}`}}. Grafana is not showing metrics.'
        summary: Thanos query errors
