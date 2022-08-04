groups:
- name: thanos-store.alerts
  rules:
    - alert: ThanosStoreGrpcErrorRate
      expr: rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable",app="thanos-store",prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      for: 5m
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_store.html'
        meta: 'Thanos store is returning errors for Prometheus {{`{{ $labels.prometheus }}`}}'
      annotations:
        description: 'Thanos Store is returning Internal/Unavailable errors for Prometheus {{`{{ $labels.prometheus }}`}}. Long Term Storage Prometheus queries are failing.'
        summary: Thanos store has errors

    - alert: ThanosStoreBucketOperationsFailed
      expr: rate(thanos_objstore_bucket_operation_failures_total{app="thanos-store",prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      for: 5m
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_store.html'
        meta: 'Thanos store failing bucket operations for Prometheus {{`{{ $labels.prometheus }}`}}.'
      annotations:
        description: 'Thanos Store is failing to do bucket operations for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries are failing.'
        summary: Thanos store failing bucket operations
