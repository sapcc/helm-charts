{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-store.alerts
  rules:
    - alert: ThanosStoreGrpcErrorRate
      expr: |
        (
          sum by (thanos) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(grpc_server_started_total{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.thanos }}`}}` is failing to handle requests.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.thanos }}`}}` is failing
          to handle `{{`{{ $value | humanize }}`}}%` of gRPC requests.
        summary: Thanos Store is failing to handle gRPC requests.

    - alert: ThanosStoreSeriesGateLatencyHigh
      expr: |
        (
          histogram_quantile(0.99, sum by (thanos, le) (rate(thanos_bucket_store_series_gate_queries_duration_seconds_bucket{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))) > 2
        and
          sum by (thanos) (rate(thanos_bucket_store_series_gate_queries_duration_seconds_bucket{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m])) > 0
        )
      for: 10m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.thanos }}`}}` has a 99th percentile latency for store series gate requests.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.thanos }}`}}` has a 99th 
          percentile latency of `{{`{{ $value }}`}}`seconds 
          for store series gate requests. 
        summary: Thanos Store has high latency for store series gate requests.

    - alert: ThanosStoreBucketHighOperationFailures
      expr: |
        (
          sum by (thanos) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_objstore_bucket_operations_total{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.thanos }}`}}` Bucket is failing to execute operations.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.thanos }}`}}` Bucket is failing
          to execute `{{`{{ $value | humanize }}`}}%` of operations.
        summary: Thanos Store Bucket is failing to execute operations.

    - alert: ThanosStoreObjstoreOperationLatencyHigh
      expr: |
        (
          sum by (thanos) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_objstore_bucket_operations_total{job=~".*thanos.*store.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 10m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Store `{{`{{ $labels.thanos }}`}}` Bucket has a 99th percentile latency for the bucket operations.
      annotations:
        description: |
          Thanos Store `{{`{{ $labels.thanos }}`}}` Bucket has a 99th
          percentile latency of `{{`{{ $value }}`}}` seconds for the
          bucket operations.
        summary: Thanos Store is having high latency for bucket operations.
