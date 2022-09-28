groups:
- name: logstash.alerts
  rules:
  - alert: ElkLogstashLogsIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: increase(logstash_node_plugin_events_in_total{cluster_type!="controlplane",namespace="logs",plugin_id="elk-syslog"}[1h]) / increase(logstash_node_plugin_events_in_total{namespace="logs",cluster_type!="controlplane",plugin_id="elk-syslog"}[1h]offset 2h) > 2
{{ else }}
    expr: increase(logstash_node_plugin_events_in_total{namespace="logs",plugin_id="elk-syslog"}[1h]) / increase(logstash_node_plugin_events_in_total{namespace="logs",plugin_id="elk-syslog"}[1h]offset 2h) > 2
{{ end }}
    for: 60m
    labels:
      context: logshipping
      service: elk
      severity: info
      tier: os
      playbook: docs/operation/elastic_kibana_issues/elk_logs/logstash_logs_increasing.html
    annotations:
      description: 'ELK logstash in {{`{{ $labels.region }}`}} {{`{{ $labels.kubernetes_pod_name }}`}} pod on {{`{{ $labels.nodename }}`}} 100 % more logs'
      summary:  logstash external receiver events increasing
