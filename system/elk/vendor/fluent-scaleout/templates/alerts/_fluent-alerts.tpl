groups:
- name: fluent.alerts
  rules:
  - alert: ElkControlplaneLogstashLogsMissing
    expr: sum(rate(fluentd_output_status_num_records_total{component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
    for: 60m
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
      playbook: docs/support/playbook/elk/fluent-logs-misssing.html
    annotations:
      description: 'ELK in {{`{{ $labels.region }}`}} {{`{{ $labels.kubernetes_pod_name }}`}} pod on {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
      summary:  logstash log shipper missing check
  - alert: ElkScaleoutLogsIncreasing
    expr: (sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h]offset 1d))) > 1.2
    for: 1h
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
    annotations:
      description: 'ELK in {{`{{ $labels.region }}`}} is receiving more logs in the last 1h compared to 24h ago.'
      summary:  fluentd controlplane, check log volume.
