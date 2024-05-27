groups:
- name: logstash.alerts
  rules:
  - alert: LogsLogstashLogsIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: increase(logstash_node_plugin_events_in_total{cluster_type!="controlplane",cluster_type!="metal",namespace="logs",plugin_id="input-tcp-syslog"}[1h]) / increase(logstash_node_plugin_events_in_total{namespace="logs",cluster_type!="controlplane",cluster_type!="metal",plugin_id="input-tcp-syslog"}[1h]offset 2h) > 2
{{ else }}
    expr: increase(logstash_node_plugin_events_in_total{namespace="logs",plugin_id="input-tcp-syslog"}[1h]) / increase(logstash_node_plugin_events_in_total{namespace="logs",plugin_id="input-tcp-syslog"}[1h]offset 2h) > 2
{{ end }}
    for: 120m
    labels:
      context: logshipping
      service: logs
      severity: info
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/opensearch/opensearch_logs/logs-increasing'
    annotations:
      description: 'logstash in {{`{{ $labels.region }}`}} {{`{{ $labels.kubernetes_pod_name }}`}} pod on {{`{{ $labels.nodename }}`}} 100 % more logs'
      summary:  logstash external receiver events increasing
