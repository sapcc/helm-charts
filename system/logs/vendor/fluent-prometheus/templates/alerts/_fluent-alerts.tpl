groups:
- name: logs-fluent-prometheus.alerts
  rules:
  - alert: LogsFluentPrometheusTailStalled
    expr: sum by (fluent_container) (increase(prom_fluentd_tail_stalled[30m])) > 0
    for: 5m
    labels:
        context: logshipping
        service: logs
        severity: info
        support_group: observability
        tier: os
    annotations:
        summary: '{{`{{ $labels.fluent_container }}`}} tail for at least one log file stalled
        description: 'tail has stopped for at least one container on watched by {{`{{ $labels.fluent_container }}`}}. Please restart the pod'
