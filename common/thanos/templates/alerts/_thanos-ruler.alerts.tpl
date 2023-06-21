{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-ruler.alerts
  rules:
    - alert: ThanosRuleQueueIsDroppingAlerts
      expr: |
        sum by (thanos) (rate(thanos_alert_queue_alerts_dropped_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m])) > 0
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to queue alerts.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to queue alerts.
        summary: Thanos Rule is failing to queue alerts.

    - alert: ThanosRuleSenderIsFailingAlerts
      expr: |
        sum by (thanos) (rate(thanos_alert_sender_alerts_dropped_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m])) > 0
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to send alerts to alertmanager.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to send alerts to alertmanager.
        summary: Thanos Rule is failing to send alerts to alertmanager.

    - alert: ThanosRuleHighRuleEvaluationFailures
      expr: |
        (
          sum by (thanos) (rate(prometheus_rule_evaluation_failures_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(prometheus_rule_evaluations_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 10m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to evaluate rules.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to evaluate rules.
        summary: Thanos Rule is failing to evaluate rules.

    - alert: ThanosRuleHighRuleEvaluationWarnings
      expr: |
        sum by (thanos) (rate(thanos_rule_evaluation_with_warnings_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m])) > 0
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` has high number of evaluation warnings.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has high number of evaluation warnings.
        summary: Thanos Rule has high number of evaluation warnings.

    - alert: ThanosRuleEvaluationLatencyHigh
      expr: |
        (
          sum by (thanos, rule_group) (prometheus_rule_group_last_duration_seconds{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"})
        >
          sum by (thanos, rule_group) (prometheus_rule_group_interval_seconds{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"})
        )
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` has high rule evaluation latency.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has higher evaluation latency than
          interval for `{{`{{ $labels.rule_group }}`}}`.
        summary: Thanos Rule has high rule evaluation latency.
    
    - alert: ThanosRuleGrpcErrorRate
      expr: |
        (
          sum by (thanos) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(grpc_server_started_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to handle grpc requests.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` is failing to handle `{{`{{ $value | humanize }}%`}}`
          of requests.
        summary: Thanos Rule is failing to handle grpc requests.
    
    - alert: ThanosRuleConfigReloadFailure
      expr: |
        avg by (thanos) (thanos_rule_config_last_reload_successful{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}) != 1
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` has not been able to reload configuration.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has not been able to reload its configuration.
        summary: Thanos Rule has not been able to reload configuration.
    
    - alert: ThanosRuleQueryHighDNSFailures
      expr: |
        (
          sum by (thanos) (rate(thanos_rule_query_apis_dns_failures_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_rule_query_apis_dns_lookups_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 1
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is having high number of DNS failures.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has `{{`{{ $value | humanize }}%`}}` of failing DNS
          queries for query endpoints.
        summary: Thanos Rule is having high number of DNS failures.

    - alert: ThanosRuleAlertmanagerHighDNSFailures
      expr: |
        (
          sum by (thanos) (rate(thanos_rule_alertmanagers_dns_failures_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_rule_alertmanagers_dns_lookups_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 1
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` is having high number of DNS failures.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has `{{`{{ $value | humanize }}%`}}` of failing
          DNS queries for Alertmanager endpoints.
        summary: Thanos Rule is having high number of DNS failures.
    
    - alert: ThanosRuleNoEvaluationFor10Intervals
      expr: |
        time() -  max by (thanos, group) (prometheus_rule_group_last_evaluation_timestamp_seconds{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"})
        >
        10 * max by (thanos, group) (prometheus_rule_group_interval_seconds{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"})
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` has rule groups that did not evaluate for 10 intervals.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` has rule groups that did not evaluate for
          at least 10x of their expected interval.
        summary: Thanos Rule has rule groups that did not evaluate for 10 intervals.
    
    - alert: ThanosNoRuleEvaluations
      expr: |
        sum by (thanos) (rate(prometheus_rule_evaluations_total{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}[5m])) <= 0
          and
        sum by (thnaos) (thanos_rule_loaded_rules{job=~".*thanos.*rule.*", thanos="{{ include "thanos.name" . }}"}) > 0
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Rule `{{`{{ $labels.thanos }}`}}` did not perform any rule evaluations.
      annotations:
        description: |
          Thanos Rule `{{`{{ $labels.thanos }}`}}` did not perform any rule evaluations
          in the past 10 minutes.
        summary: Thanos Rule did not perform any rule evaluations.
