groups:
- name: fluent.alerts
  rules:
  - alert: ElkFluentLogsMissing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: sum(rate(fluentd_output_status_num_records_total{cluster_type!="controlplane",component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
{{ else }}
    expr: sum(rate(fluentd_output_status_num_records_total{component="fluent"}[30m])) by (nodename,kubernetes_pod_name) == 0
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
  - alert: ElkFluentLogsIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: (sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",component="fluent",type="elasticsearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",component="fluent",type="elasticsearch"}[1h]offset 2h))) > 1.4
{{ else }}
    expr: (sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h]offset 2h))) > 1.4
{{ end }}
    for: 1h
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
    annotations:
      description: 'ELK in {{`{{ $labels.region }}`}} is receiving more logs in the last 1h compared to 24h ago.'
      summary:  fluentd container logs increasing, check log volume.
