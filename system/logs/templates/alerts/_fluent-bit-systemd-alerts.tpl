groups:
- name: logs-fluent-bit-systemd.alerts
  rules:
  - alert: LogsFluentBitSystemdLogsMissing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: sum(rate(fluentbit_output_proc_records_total{job="logs-fluent-bit-systemd-exporter",cluster_type!="controlplane",cluster_type!="metal"}[60m])) by (nodename,name) == 0
    for: 180m
{{ else }}
    expr: sum(rate(fluentbit_output_proc_records_total{job="logs-fluent-bit-systemd-exporter"}[60m])) by (nodename,name) == 0
    for: 120m
{{ end }}
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/opensearch/opensearch_logs/fluent-logs-are-missing'
    annotations:
{{ if eq .Values.global.clusterType  "scaleout" }}
      description: 'logs-fluent-bit-systemd on `scaleout` {{`{{ $labels.nodename }}`}} is not shipping logs to {{`{{ $labels.name }}`}}. Please check'
{{ else }}
      description: 'logs-fluent-bit-systemd on `metal` {{`{{ $labels.nodename }}`}} is not shipping logs to {{`{{ $labels.name }}`}}. Please check'
{{ end }}
      summary: logs-fluent-bit-systemd is not shipping logs
  - alert: LogsFluentBitSystemdLogsIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: (sum(increase(fluentbit_output_proc_records_total{cluster_type!="controlplane",cluster_type!="metal",job="logs-fluent-bit-systemd-exporter"}[1h])) by (name) / sum(increase(fluentbit_output_proc_records_total{cluster_type!="controlplane",cluster_type!="metal",job="logs-fluent-bit-systemd-exporter"}[1h]offset 2h)) by (name)) > 4
{{ else }}
    expr: (sum(increase(fluentbit_output_proc_records_total{job="logs-fluent-bit-systemd-exporter"}[1h])) by (name) / sum(increase(fluentbit_output_proc_records_total{job="logs-fluent-bit-systemd-exporter"}[1h]offset 2h)) by (name)) > 4
{{ end }}
    for: 6h
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/opensearch/opensearch_logs/systemd-logs-are-missing'
    annotations:
      description: 'logs-fluent-bit-systemd target: {{`{{ $labels.name }}`}}  in {{`{{ $labels.region }}`}} is receiving 4 times more logs in the last 6h. Please check'
      summary:  logs-fluent-bit-systemd  log volume is increasing, check log volume.
