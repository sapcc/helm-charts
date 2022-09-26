groups:
- name: logstash.alerts
  rules:
  - alert: ElkLogstashLogsMissing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: sum(rate(fluentd_output_status_num_records_total{cluster_type!="controlplane",component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
{{ else }}
    expr: sum(rate(fluentd_output_status_num_records_total{cluster_type="controlplane",component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
{{ end }}
    for: 60m
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
      playbook: docs/operation/elastic_kibana_issues/elk_logs/fluent-logs-are-missing.html
    annotations:
      description: 'ELK in {{`{{ $labels.region }}`}} {{`{{ $labels.kubernetes_pod_name }}`}} pod on {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
      summary:  logstash log shipper missing check
