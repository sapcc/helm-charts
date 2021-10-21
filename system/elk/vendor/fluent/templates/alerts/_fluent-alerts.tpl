groups:
- name: fluent.alerts
  rules:
  - alert: ElkControlplaneLogstashLogsMissing
    expr: sum(rate(fluentd_output_status_num_records_total{component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
    for: 30m
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
      playbook: docs/support/playbook/elastic_kibana_issues.html#fluent-logs-are-missing
    annotations:
      description: 'ELK in {{ $labels.region }} `{{ $labels.kubernetes_pod_name }}` pod on `{{ $labels.nodename }}` is not shipping any log line. Please check'
      summary:  logstash log shipper missing check
  - alert: ElkControlplaneLogsIncreasing
    expr: sum(rate(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[15m])) > {{ .Values.alerts.max_events }}
    for: 60m
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
    annotations:
      description: 'ELK in {{ $labels.region }} is getting more logs, than usual in the last 1h.'
      summary:  fluentd controlplane, check log volume.
