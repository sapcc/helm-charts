{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-sidecar.alerts
  rules:
    - alert: ThanosSidecarBucketOperationsFailed
      expr: rate(thanos_objstore_bucket_operation_failures_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      for: 5m
      labels:
        context: thanos
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: observability
        severity: info
        meta: 'Thanos Sidecar bucket operations are failing for Prometheus `{{`{{ $labels.prometheus }}`}}`'
        playbook: 'docs/support/playbook/prometheus/thanos_sidecar.html'
      annotations:
        description: 'Thanos Sidecar bucket operations are failing for Prometheus `{{`{{ $labels.prometheus }}`}}`. Metrics data will be lost if not fixed in 24h.'
        summary: Thanos Sidecar bucket operations are failing

    - alert: ThanosSidecarGrpcErrorRate
      expr: rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable",name="prometheus"}[5m]) > 0
      for: 5m
      labels:
        context: thanos
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: observability
        severity: info
        meta: 'Thanos Sidecar is returning Internal/Unavailable errors for Prometheus `{{`{{ $labels.prometheus }}`}}`'
        playbook: 'docs/support/playbook/prometheus/thanos_sidecar.html'
      annotations:
        description: 'Thanos Sidecar is returning Internal/Unavailable errors for Prometheus `{{`{{ $labels.prometheus }}`}}`. Prometheus queries are failing.'
        summary: Thanos Sidecar is returning Internal/Unavailable errors
