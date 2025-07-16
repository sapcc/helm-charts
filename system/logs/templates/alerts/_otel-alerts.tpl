groups:
- name: logs-otel.alerts
  rules:
  - alert: LogsOTelLogsMissing
    expr: sum by (region, k8s_node_name, pod) (rate(otelcol_exporter_sent_log_records_total{job="logs/opentelemetry-collector-logs", exporter !~"debug"}[60m])) == 0
    for: 120m
    labels:
      context: logshipping
      service: otel
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/logs/otel-logs-missing'
    annotations:
      description: 'OpenTelemetry Collector on {{`{{ $labels.k8s_node_name }}`}} in {{`{{ $labels.region }}`}} is not shipping logs. Please check.'
      summary: OTel is not shipping logs
  - alert: LogsOTelLogsIncreasing
    expr: sum(increase(otelcol_exporter_sent_log_records_total{job="logs/opentelemetry-collector-logs"}[1h])) by (name) / sum(increase(otelcol_exporter_sent_log_records_total{job="logs/opentelemetry-collector-logs"}[1h]offset 2h)) by (name) > 4
    for: 6h
    labels:
      context: logshipping
      service: otel
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/logs/otel-logs-increasing'
    annotations:
      description: 'OTel logs on {{`{{ $labels.k8s_node_name }}`}} in {{`{{ $labels.region }}`}} is sending 4 times more logs in the last 6h. Please check.'
      summary:  OTel log volume is increasing, check log volume.
  - alert: LogsOTelLogsDecreasing
    expr: sum(rate(otelcol_exporter_sent_log_records_total{job="logs/opentelemetry-collector-logs"}[1h]offset 2h)) by (name)/sum(rate(otelcol_exporter_sent_log_records_total{job="logs/opentelemetry-collector-logs"}[1h])) by (name) > 3
    for: 2h
    labels:
      context: logshipping
      service: otel
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/logs/otel-logs-decreasing'
    annotations:
      description: 'OTel on {{`{{ $labels.k8s_node_name }}`}} in {{`{{ $labels.region }}`}} is sending 3 times fewer logs in the last 2h. Please check.'
      summary:  OTel log volume is decreasing, check log volume.

