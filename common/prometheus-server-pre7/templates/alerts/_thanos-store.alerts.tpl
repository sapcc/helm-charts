groups:
- name: thanos-store.alerts
  rules:
    - alert: ThanosStoreGrpcErrorRate
      expr: |
        (
          sum by (prometheus) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        /
          sum by (prometheus) (rate(grpc_server_started_total{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        service: {{ default "metrics" .Values.alerts.service }}
        support_group: {{ default "observability" .Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.prometheus }}`}}` is failing to handle requests.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.prometheus }}`}}` is failing
          to handle `{{`{{ $value | humanize }}`}}%` of gRPC requests.
        summary: Thanos Store is failing to handle gRPC requests.

    - alert: ThanosStoreSeriesGateLatencyHigh
      expr: |
        (
          histogram_quantile(0.99, sum by (prometheus, le) (rate(thanos_bucket_store_series_gate_queries_duration_seconds_bucket{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))) > 2
        and
          sum by (prometheus) (rate(thanos_bucket_store_series_gate_queries_duration_seconds_count{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m])) > 0
        )
      for: 10m
      labels:
        service: {{ default "metrics" .Values.alerts.service }}
        support_group: {{ default "observability" .Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.prometheus }}`}}` has a 99th percentile latency for store series gate requests.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.prometheus }}`}}` has a 99th
          percentile latency of `{{`{{ $value }}`}}`seconds
          for store series gate requests.
        summary: Thanos Store has high latency for store series gate requests.

    - alert: ThanosStoreBucketHighOperationFailures
      expr: |
        (
          sum by (prometheus) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        /
          sum by (prometheus) (rate(thanos_objstore_bucket_operations_total{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        service: {{ default "metrics" .Values.alerts.service }}
        support_group: {{ default "observability" .Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.prometheus }}`}}` Bucket is failing to execute operations.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.prometheus }}`}}` Bucket is failing
          to execute `{{`{{ $value | humanize }}`}}%` of operations.
        summary: Thanos Store Bucket is failing to execute operations.

    - alert: ThanosStoreObjstoreOperationLatencyHigh
      expr: |
        (
          sum by (prometheus) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        /
          sum by (prometheus) (rate(thanos_objstore_bucket_operations_total{job=~".*thanos.*store.*", prometheus="{{ include "prometheus.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 10m
      labels:
        service: {{ default "metrics" .Values.alerts.service }}
        support_group: {{ default "observability" .Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.prometheus }}`}}` Bucket has a 99th percentile latency for the bucket operations.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.prometheus }}`}}` Bucket has a 99th
          percentile latency of `{{`{{ $value }}`}}` seconds for the
          bucket operations.
        summary: Thanos Store is having high latency for bucket operations.
