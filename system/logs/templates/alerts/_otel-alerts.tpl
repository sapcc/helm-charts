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
      description: 'lotel-logs on {{`{{ $labels.k8s_node_name }}`}} in {{`{{ $labels.region }}`}} is sending 4 times more logs in the last 6h. Please check.'
      summary:  OTel log volume is increasing, check log volume.
  - alert: LogsTestAlertManagerGreenhouse
    expr: otelcol_exporter_send_failed_log_records_total{k8s_cluster_name="qa-de-1",k8s_node_name=~"storage-1.*"}
    for: 5m
    labels:
      context: logshipping
      service: otel
      severity: warning
      support_group: observability
      tier: os
      playbook: 'https://github.com/cloudoperators/greenhouse-extensions/tree/main/logs/playbooks/OTelLogsMissing.md'
    annotations:
      description: 'This is just a test alert for AlertManager Greenhouse.'
      summary:  This is just a test alert for AlertManager Greenhouse.
  - alert: LogsTestAlertManagerSCI
    expr: otelcol_exporter_send_failed_log_records_total{k8s_cluster_name="qa-de-1",k8s_node_name=~"storage-1.*"}
    for: 5m
    labels:
      context: logshipping
      service: otel
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/logs/otel-logs-increasing'
    annotations:
      description: 'This is just a test alert for AlertManager SCI.'
      summary:  This is just a test alert for AlertManager SCI.



