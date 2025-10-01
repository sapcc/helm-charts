{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-query.alerts
  rules:
    - alert: ThanosQueryHttpRequestQueryErrorRateHigh
      expr: |
        (
          sum by (thanos) (rate(http_requests_total{code=~"5..", job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query"}[5m]))
        /
          sum by (thanos) (rate(http_requests_total{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to handle requests.
        no_alert_on_absence: "true"
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to
          handle `{{`{{ $value | humanize }}`}}%` of "query" requests.
        summary: Thanos Query is failing to handle requests.

    - alert: ThanosQueryHttpRequestQueryRangeErrorRateHigh
      expr: |
        (
          sum by (thanos) (rate(http_requests_total{code=~"5..", job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query_range"}[5m]))
        /
          sum by (thanos) (rate(http_requests_total{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query_range"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to handle requests.
        no_alert_on_absence: "true"
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to
          handle `{{`{{ $value | humanize }}`}}%` of "query_range" requests.
        summary: Thanos Query is failing to handle requests.

    - alert: ThanosQueryGrpcServerErrorRate
      expr: |
        (
          sum by (thanos) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(grpc_server_started_total{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to handle gRPC requests.
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to
          handle `{{`{{ $value | humanize }}`}}%` of gRPC requests.
        summary: Thanos Query is failing to handle gRPC requests.

    - alert: ThanosQueryGrpcClientErrorRate
      expr: |
        (
          sum by (thanos) (rate(grpc_client_handled_total{grpc_code!="OK", job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(grpc_client_started_total{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to send gRPC requests.
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` is failing to
          send `{{`{{ $value | humanize }}`}}%` gRPC requests.
        summary: Thanos Query is failing to send gRPC requests.

    - alert: ThanosQueryInstantLatencyHigh
      expr: |
        (
          histogram_quantile(0.99, sum by (thanos, le) (rate(http_request_duration_seconds_bucket{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query"}[5m]))) > 40
        and
          sum by (thanos) (rate(http_request_duration_seconds_bucket{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query"}[5m])) > 0
        )
      for: 10m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` has a 99th percentile latency for instant queries.
        no_alert_on_absence: "true"
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` has a 99th
          percentile latency of `{{`{{ $value }}`}}` seconds
          for instant queries.
        summary: Thanos Query has high latency for instant queries.

    - alert: ThanosQueryRangeLatencyHigh
      expr: |
        (
          histogram_quantile(0.99, sum by (thanos, le) (rate(http_request_duration_seconds_bucket{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query_range"}[5m]))) > 40
        and
          sum by (thanos) (rate(http_request_duration_seconds_bucket{job=~".*thanos.*query.*", thanos="{{ include "thanos.name" . }}", handler="query_range"}[5m])) > 0
        )
      for: 10m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` has a 99th percentile latency for range queries.
        no_alert_on_absence: "true"
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` has a 99th
          percentile latency of `{{`{{ $value }}`}}` seconds
          for range queries.
        summary: Thanos Query has high latency for queries.

    - alert: ThanosQueryOverload
      expr: |
        (
          max_over_time(thanos_query_concurrent_gate_queries_max[5m]) - avg_over_time(thanos_query_concurrent_gate_queries_in_flight[5m]) < 1
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Query `{{`{{ $labels.thanos }}`}}` has been overloaded for more than 15 minutes.
      annotations:
        description: |
          Thanos Query `{{`{{ $labels.thanos }}`}}` has been overloaded
          for more than 15 minutes. This may be a symptom of excessive
          simultanous complex requests, low performance of the Prometheus
          API, or failures within these components. Assess the health
          of the Thanos Query instances, the connnected Prometheus
          instances, and increase the number of Thanos Query replicas.
        summary: Thanos Query reaches its maximum capacity serving concurrent requests.
