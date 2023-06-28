groups:
- name: fluent.alerts
  rules:
  - alert: ElkFluentLogsMissing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: sum by (nodename) (rate(fluentd_output_status_emit_records{cluster_type!="controlplane",component="fluent",type="elasticsearch"}[60m])) == 0
    for: 360m
{{ else }}
    expr: sum by (nodename) (rate(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[60m])) == 0
    for: 180m
{{ end }}
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
      playbook: docs/operation/elastic_kibana_issues/elk_logs/fluent-logs-are-missing
    annotations:
{{ if eq .Values.global.clusterType  "scaleout" }}
      description: 'No fluent container logs from  `scaleout` {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
{{ else }}
      description: 'No fLuent container logs from `metal` {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
{{ end }}
      summary: fluent container is not shipping logs
  - alert: ElkFluentLogsIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: (sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",component="fluent",type="elasticsearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",component="fluent",type="elasticsearch"}[1h]offset 2h))) > 2
{{ else }}
    expr: (sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{component="fluent",type="elasticsearch"}[1h]offset 2h))) > 4
{{ end }}
    for: 6h
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
    annotations:
      description: 'ELK in {{`{{ $labels.region }}`}} is receiving 4 times more logs in the last 6h.'
      summary:  fluentd container logs increasing, check log volume.
