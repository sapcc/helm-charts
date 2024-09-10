groups:
- name: fluent.alerts
  rules:
  - alert: OpenSearchLogsFluentLogsMissing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: sum by (nodename) (rate(fluentd_output_status_emit_records{cluster_type!="controlplane",cluster_type!="metal",component="fluent",type="opensearch"}[60m])) == 0
    for: 360m
{{ else }}
    expr: sum by (nodename) (rate(fluentd_output_status_emit_records{component="fluent",type="opensearch"}[60m])) == 0
    for: 180m
{{ end }}
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
      playbook: 'docs/support/playbook/opensearch/opensearch_logs/container-logs-are-missing'
    annotations:
{{ if eq .Values.global.clusterType  "scaleout" }}
      description: 'No fluent container logs from  `scaleout` {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
{{ else }}
      description: 'No fLuent container logs from `metal` {{`{{ $labels.nodename }}`}} is not shipping any log line. Please check'
{{ end }}
      summary: fluent container is not shipping logs
  - alert: OpenSearchLogsFluentContainerIncreasing
{{ if eq .Values.global.clusterType  "scaleout" }}
    expr: (sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",cluster_type!="metal",component="fluent",type="opensearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{cluster_type!="controlplane",cluster_type!="metal",component="fluent",type="opensearch"}[1h]offset 2h))) > 2
{{ else }}
    expr: (sum(increase(fluentd_output_status_emit_records{component="fluent",type="opensearch"}[1h])) / sum(increase(fluentd_output_status_emit_records{component="fluent",type="opensearch"}[1h]offset 2h))) > 4
{{ end }}
    for: 6h
    labels:
      context: logshipping
      service: logs
      severity: warning
      support_group: observability
      tier: os
    annotations:
      description: 'OpenSearch logs in {{`{{ $labels.region }}`}} is receiving 4 times more logs in the last 6h.'
      summary:  fluentd container logs increasing, check log volume.
