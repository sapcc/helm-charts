{{- /*
Taken from prometheus-rules/prometheus-kubernetes-rules, since it is used in the common chart and every prometheus needs to have it or the chart will fail
*/}}
{{- /*
Use the 'label_alert_tier', if it exists on the time series, otherwise use the given default.
Note: The pods define the 'alert-tier' label but Prometheus replaces the hyphen with an underscore.
*/}}
{{- define "alertTierLabelOrDefault" -}}
"{{`{{ if $labels.label_alert_tier }}`}}{{`{{ $labels.label_alert_tier}}`}}{{`{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}
{{- /*
Use the 'label_alert_service', if it exists on the time series, otherwise use the given default.
Note: The pods define the 'alert-service' label but Prometheus replaces the hyphen with an underscore.
*/}}
{{- define "alertServiceLabelOrDefault" -}}
"{{`{{ if $labels.label_alert_service }}`}}{{`{{ $labels.label_alert_service}}`}}{{`{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}

groups:
- name: prometheus.alerts
  rules:
  - alert: PrometheusFailedConfigReload
    expr: prometheus_config_last_reload_successful{prometheus="{{ include "prometheus.name" . }}"} == 0
    for: 5m
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: critical
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_config_reload.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} failed to load it`s configuration.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} failed to load it`s configuration. Prometheus cannot start with a malformed configuration.'
      summary: Prometheus configuration reload has failed

  - alert: PrometheusRuleEvaluationFailed
    expr: increase(prometheus_rule_evaluation_failures_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    for: 15m
    labels:
      context: availability
      service: prometheus
      severity: warning
      support_group: observability
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/rule_evaluation.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} failed to evaluate rules.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} failed to evaluate rules. Aggregation or alerting rules may not be loaded or provide false results.'
      summary: Prometheus rule evaluation failed

  - alert: PrometheusRuleEvaluationSlow
    expr: prometheus_rule_evaluation_duration_seconds{quantile="0.9", prometheus="{{ include "prometheus.name" . }}"} > 60
    for: 10m
    labels:
      context: availability
      service: prometheus
      severity: info
      support_group: observability
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/rule_evaluation.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} rule evaluation is slow.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} rule evaluation is slow'
      summary: Prometheus rule evaluation is slow

  - alert: PrometheusWALCorruption
    expr: increase(prometheus_tsdb_wal_corruptions_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    labels:
      context: availability
      service: prometheus
      severity: info
      support_group: observability
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/wal.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} has {{`{{ $value }}`}} WAL corruptions.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}}  has {{`{{ $value }}`}} WAL corruptions.'
      summary: Prometheus has WAL corruptions

  - alert: PrometheusTSDBReloadsFailing
    expr: increase(prometheus_tsdb_reloads_failures_total{prometheus="{{ include "prometheus.name" . }}"}[2h]) > 0
    for: 12h
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_tsdb_reload.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} failed to reload TSDB.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} had {{`{{$value | humanize}}`}} reload failures over the last four hours.'
      summary: Prometheus has issues reloading data blocks from disk

  - alert: PrometheusNotIngestingSamples
    expr: rate(prometheus_tsdb_head_samples_appended_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) <= 0 or absent(prometheus_tsdb_head_samples_appended_total{prometheus="{{ include "prometheus.name" . }}"}) or absent(scrape_samples_scraped{prometheus="{{ include "prometheus.name" . }}"})
    for: 10m
    labels:
      context: availability
      service: prometheus
      severity: info
      support_group: observability
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_scrapes.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} not ingesting samples.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} not ingesting samples. Aggregation or alerting rules may not be loaded or provide false results.'
      summary: Prometheus not ingesting samples.

  - alert: PrometheusTargetScrapesDuplicate
    expr: increase(prometheus_target_scrapes_sample_duplicate_timestamp_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    for: 10m
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_scrapes.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} rejects many samples'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} has many samples rejected due to duplicate timestamps but different values. This indicates metric duplication.'
      summary: Prometheus rejects many samples

  - alert: PrometheusOutOfOrderTimestamps
    expr: rate(prometheus_target_scrapes_sample_out_of_order_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_scrapes.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} drops samples with out-of-order timestamps.'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} has many samples rejected due to out-of-order timestamps.'
      summary: Prometheus drops samples with out-of-order timestamps

  - alert: PrometheusLargeScrapes
    expr: increase(prometheus_target_scrapes_exceeded_sample_limit_total{prometheus="{{ include "prometheus.name" . }}"}[30m]) > 60
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_scrapes.html'
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} fails to scrape targets'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} has many scrapes that exceed the sample limit'
      summary: Prometheus fails to scrape targets.

  - alert: PrometheusMultipleTargetScrapes
    # we exclude cadvisor metrics because it has the same instance as the kubelet but a different path
    # e.g. 10.246.204.80:10250/metrics vs. 10.246.204.80:10250/metrics/cadvisor
    # We also exclude the pod service discovery job, we have a dedicated alert for that
    expr: sum by (job) (up * on(instance, cluster) group_left() (sum by(instance, cluster) (up{job !~ "kubernetes-cadvisors|kubernetes-kubelet|.*-pod-sd"}) > 1))
    for: 30m
    labels:
      tier: {{ include "alerts.tier" . }}
      service: prometheus
      support_group: observability
      severity: warning
      playbook: docs/support/playbook/kubernetes/target_scraped_multiple_times.html
      meta: 'Prometheus is scraping targets of job {{`{{ $labels.job }}`}} more than once.'
    annotations:
      description: Prometheus is scraping individual targets of the job `{{`{{ $labels.job }}`}}` more than once. This is likely caused due to incorrectly placed scrape annotations.  <https://{{ include "prometheus.externalURL" . }}/graph?g0.expr={{ urlquery `up * on(instance) group_left() (sum by(instance) (up{job="PLACEHOLDER"}) > 1)` | replace "PLACEHOLDER" "{{ $labels.job }}"}}|Affected targets>
      summary: Prometheus target scraped multiple times

  - alert: AlertWithMissingSupportGroupLabel
    expr: max by(alertname) (ALERTS{support_group=""})
    for: 5m
    labels:
      tier: {{ include "alerts.tier" . }}
      service: prometheus
      support_group: observability
      severity: info
      playbook: docs/support/operation_model/tags.html
      meta: 'Alert {{`{{ $labels.alertname }}`}} is missing the `support_group` label'
    annotations:
      description: Alert `{{`{{ $labels.alertname }}`}}` is missing the required `support_group` label
      summary: Alert is missing support_group label

  {{- if and .Values.alertmanagers (gt (len .Values.alertmanagers) 0) }}
  - alert: PrometheusNotConnectedToAlertmanagers
    expr: prometheus_notifications_alertmanagers_discovered{prometheus="{{ include "prometheus.name" . }}"} == 0
    for: 10m
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: warning
      tier: {{ include "alerts.tier" . }}
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} lost connection to all Alertmanagers'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} lost connection to all configured Alertmanagers. Alerting is unavailable.'
      summary: Prometheus not connected to any Alertmanager

  - alert: PrometheusErrorSendingAlerts
    expr: rate(prometheus_notifications_errors_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) / rate(prometheus_notifications_sent_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0.01
    for: 10m
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} fails to send alerts'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} is having errors sending alerts to Alertmanager {{`{{ $labels.alertmanager }}`}}'
      summary: Prometheus fails to send alerts

  - alert: PrometheusNotificationsBacklog
    expr: prometheus_notifications_queue_length{prometheus="{{ include "prometheus.name" . }}"} > 0
    for: 10m
    labels:
      context: availability
      service: prometheus
      support_group: observability
      severity: info
      tier: {{ include "alerts.tier" . }}
      meta: 'Prometheus {{`{{ $labels.prometheus }}`}} queueing notifications'
    annotations:
      description: 'Prometheus {{`{{ $labels.prometheus }}`}} is backlogging on the notifications queue. The queue has not been empty for 10 minutes. Current queue length {{`{{ $value }}`}}.'
      summary: Prometheus is queueing notifications.
  {{- end }}
