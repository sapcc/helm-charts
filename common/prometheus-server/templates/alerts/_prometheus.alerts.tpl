{{- /*
Taken from prometheus-rules/prometheus-kubernetes-rules, since it is used in the common chart and every prometheus needs to have it or the chart will fail
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
{{- define "alertSupportGroupOrDefault" -}}
"{{`{{ if $labels.ccloud_support_group }}`}}{{`{{ $labels.ccloud_support_group }}`}}{{`{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}

{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: prometheus.alerts
  rules:
  - alert: PrometheusFailedConfigReload
    # Without max_over_time, failed scrapes could create false negatives, see
    # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
    expr: max_over_time(prometheus_config_last_reload_successful{prometheus="{{ include "prometheus.name" . }}"}[5m]) == 0
    for: 10m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: critical
      playbook: docs/support/playbook/prometheus/failed_config_reload
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` failed to load it`s configuration.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` failed to 
        load it`s configuration. Prometheus cannot start with 
        a malformed configuration.
      summary: Prometheus configuration reload has failed.

  - alert: PrometheusRuleFailures
    expr: |
      increase(prometheus_rule_evaluation_failures_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      playbook: docs/support/playbook/prometheus/rule_evaluation
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` has failed to evaluate rules since at least 15m.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` has failed
        to evaluate `{{`{{ printf "%.0f" $value }}`}}` rules in the last 5m.
        Aggregation or alerting rules may not be loaded or
        provide false results.
      summary: Prometheus is failing rule evaluations.

  - alert: PrometheusMissingRuleEvaluations
    expr: |
      increase(prometheus_rule_group_iterations_missed_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      playbook: docs/support/playbook/prometheus/rule_evaluation
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` is missing rule evaluations due to slow rule group evaluation.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` has missed
        `{{`{{ printf "%.0f" $value }}`}}` rule group evaluations in the last 5m.
        Aggregation or alerting rules may provide false results.
      summary: Prometheus is missing rule evaluations due to slow rule group evaluation.

  - alert: PrometheusWALCorruption
    expr: |
      round(increase(prometheus_tsdb_wal_corruptions_total{prometheus="{{ include "prometheus.name" . }}"}[2h1m]) > 0)
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/wal
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` has WAL corruptions.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` has `{{`{{ $value }}`}}` WAL corruptions.
      summary: Prometheus has WAL corruptions.

  - alert: PrometheusTSDBReloadsFailing
    expr: |
      increase(prometheus_tsdb_reloads_failures_total{prometheus="{{ include "prometheus.name" . }}"}[3h]) > 0
    for: 4h
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/failed_tsdb_reload
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` failed to reload TSDB.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` had `{{`{{$value | humanize}}`}}`
        reload failures over the last three hours.
      summary: Prometheus has issues reloading data blocks from disk.

  - alert: PrometheusTSDBCompactionsFailing
    expr: |
      increase(prometheus_tsdb_compactions_failed_total{prometheus="{{ include "prometheus.name" . }}"}[3h]) > 0
    for: 4h
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/prom_compaction_errors
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` has issues compacting blocks.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` has detected `{{`{{$value | humanize}}`}}`
        compaction failures over the last 3h.
      summary: Prometheus has issues has issues compacting blocks.

  - alert: PrometheusNotIngestingSamples
    expr: |
      (
        rate(prometheus_tsdb_head_samples_appended_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) <= 0
      and
        (
          sum without(scrape_job) (prometheus_target_metadata_cache_entries{prometheus="{{ include "prometheus.name" . }}"}) > 0
        or
          sum without(rule_group) (prometheus_rule_group_rules{prometheus="{{ include "prometheus.name" . }}"}) > 0
        )
      )
    for: 10m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/failed_scrapes
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` not ingesting samples.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` not
        ingesting samples. Aggregation or alerting rules
        may not be loaded or provide false results.
      summary: Prometheus not ingesting samples.

  - alert: PrometheusDuplicateTimestamps
    expr: |
      rate(prometheus_target_scrapes_sample_duplicate_timestamp_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
    for: 10m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/failed_scrapes
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` is dropping samples with duplicate timestamps.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` is dropping
        `{{`{{ printf "%.4g" $value  }}`}}` samples/s with different values
        but duplicated timestamp. This indicates metric duplication.
      summary: Prometheus is dropping samples with duplicate timestamps.

  - alert: PrometheusOutOfOrderTimestamps
    expr: |
      rate(prometheus_target_scrapes_sample_out_of_order_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0.1
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      playbook: docs/support/playbook/prometheus/failed_scrapes
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` drops samples with out-of-order timestamps.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` is dropping
        `{{`{{ printf "%.4g" $value  }}`}}` samples/s with timestamps arriving
        out of order.
      summary: Prometheus drops samples with out-of-order timestamps.

  - alert: PrometheusTargetSyncFailure
    expr: |
      increase(prometheus_target_sync_failed_total{prometheus="{{ include "prometheus.name" . }}"}[30m]) > 0
    for: 5m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      playbook: docs/support/playbook/prometheus/failed_scrapes
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` could not synchronize targets.
    annotations:
      description: |
        Targets in Prometheus `{{`{{ $labels.prometheus }}`}}` have failed to sync because invalid configuration was supplied.
        <https://{{ include "prometheus.externalURL" . }}/graph?g0.expr={{ urlquery `sum by (scrape_job) (increase(prometheus_target_sync_failed_total{prometheus="PLACEHOLDER"}[30m])) > 0` | replace "PLACEHOLDER" "{{ $labels.prometheus }}"}}|Affected targets>
      summary: Prometheus has failed to sync targets.

  - alert: PrometheusHighQueryLoad
    expr: |
      avg_over_time(prometheus_engine_queries{prometheus="{{ include "prometheus.name" . }}"}[5m])
      /
      max_over_time(prometheus_engine_queries_concurrent_max{prometheus="{{ include "prometheus.name" . }}"}[5m])
      >
      0.8
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: critical
      playbook: docs/support/playbook/prometheus/failed_scrapes
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` is reaching its maximum capacity serving concurrent requests.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` query API
        has less than 20% available capacity in its query
        engine for the last 15 minutes.
      summary: Prometheus is reaching its maximum capacity serving concurrent requests.

  {{- if $root.Values.alerts.multipleTargetScrapes.enabled }}
  - alert: PrometheusMultipleTargetScrapes
    # We axclude * pod service discovery job, we have a dedicated alert for that
    expr: sum by (job, ccloud_support_group) (up * on(instance, cluster) group_left() (sum by(instance, cluster) (up{job!~".*pod-sd|{{ $root.Values.alerts.multipleTargetScrapes.exceptions | join "|" }}"}) > 1))
    for: 30m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ include "alertSupportGroupOrDefault" "observability" }}
      severity: warning
      playbook: docs/support/playbook/kubernetes/target_scraped_multiple_times
      meta: Prometheus is scraping targets of job `{{`{{ $labels.job }}`}}` more than once.
    annotations:
      description: |
        Prometheus is scraping individual targets of the
        job `{{`{{ $labels.job }}`}}` more than once.
        This is likely caused due to incorrectly placed
        scrape annotations.  <https://{{ include "prometheus.externalURL" . }}/graph?g0.expr={{ urlquery `up * on(instance) group_left() (sum by(instance) (up{job="PLACEHOLDER"}) > 1)` | replace "PLACEHOLDER" "{{ $labels.job }}"}}|Affected targets>
      summary: Prometheus target scraped multiple times.
  {{- end }}

  {{/* Only affecting all prometheus-kubernetes and kubernikus since they have the metric natively. Rest is provided with similar Thanos rules and must not have these alerts, since they can never fire and will trigger absent alerts */}}
  {{- if and 
  (not $root.Values.alerts.thanos.enabled)
  (not (contains (include "prometheus.name" . ) "kubernetes"))
  (not (contains (include "prometheus.name" . ) "kubernikus"))
   -}}
  {{- fail "These alerts can't fire since your Prometheus does not natively have the needed metrics. Set alerts.thanos.enabled and alerts.thanos.name to ensure proper monitoring." -}}
  {{- end}}
  {{- if and $root.Values.alerts.multiplePodScrapes.enabled (not $root.Values.alerts.thanos.enabled) }}
  - alert: PrometheusMultiplePodScrapes
    expr: sum by(pod, namespace, label_alert_service, label_alert_tier, ccloud_support_group) (label_replace((up * on(instance) group_left() (sum by(instance) (up{job=~".*{{ include "prometheus.name" . }}.*pod-sd"}) > 1)* on(pod) group_left(label_alert_tier, label_alert_service) (max without(uid) (kube_pod_labels))) , "pod", "$1", "kubernetes_pod_name", "(.*)-[0-9a-f]{8,10}-[a-z0-9]{5}"))
    for: 30m
    labels:
      service: {{ include "alertServiceLabelOrDefault" "metrics" }}
      support_group: {{ include "alertSupportGroupOrDefault" "observability" }}
      severity: warning
      playbook: docs/support/playbook/kubernetes/target_scraped_multiple_times
      meta: Prometheus is scraping `{{`{{ $labels.pod }}`}}` pods more than once.
    annotations:
      description: Prometheus is scraping `{{`{{ $labels.pod }}`}}` pods in namespace `{{`{{ $labels.namespace }}`}}` multiple times. This is likely caused due to incorrectly placed scrape annotations. <https://{{ include "prometheus.externalURL" . }}/graph?g0.expr={{ urlquery `up * on(instance) group_left() (sum by(instance) (up{kubernetes_pod_name=~"PLACEHOLDER.*"}) > 1)` | replace "PLACEHOLDER" "{{ $labels.pod }}"}}|Affected targets>
      summary: Prometheus scrapes pods multiple times
  {{- end }}

  {{- if and (eq $root.Values.vpaUpdateMode "Auto") (not $root.Values.alerts.thanos.enabled) }}
  - alert: PrometheusVpaMemoryExceeded
    expr: |
      round(vpa_butler_vpa_container_recommendation_excess{verticalpodautoscaler=~"{{ include "prometheus.fullName" . }}",resource="memory"} / 1024 / 1024 / 1024, 0.1 ) > 5
    for: 4d
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      meta: Prometheus VPA for `{{`{{ $labels.verticalpodautoscaler }}`}}` in `{{`{{ $labels.namespace }}`}}` is recommending more memory.
    annotations:
      description: |
        `{{`{{ $labels.verticalpodautoscaler }}`}}` in `{{`{{ $labels.cluster }}/{{ $labels.namespace }}`}}` needs more `{{`{{ $labels.resource }}`}}`. It is overutilized by `{{`{{ $value }}`}}` GiB.
        It is hitting the VPA maxAllowed boundary and is not ensured to run properly at its current place. Consider upgrading the VPA maxAllowed
        memory value if the host memory size permits.
      summary: Prometheus needs more memory.

  - alert: PrometheusVpaCPUExceeded
    expr: |
      round(vpa_butler_vpa_container_recommendation_excess{verticalpodautoscaler=~"{{ include "prometheus.fullName" . }}",resource="cpu"}, 0.1) > 0.5
    for: 4d
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: info
      meta: Prometheus VPA for `{{`{{ $labels.verticalpodautoscaler }}`}}` in `{{`{{ $labels.namespace }}`}}` is recommending more CPUs.
    annotations:
      description: |
        `{{`{{ $labels.verticalpodautoscaler }}`}}` in `{{`{{ $labels.cluster }}/{{ $labels.namespace }}`}}` needs more `{{`{{ $labels.resource }}`}}`. It is overutilized by `{{`{{ $value }}`}}` cores.
        It is hitting the VPA maxAllowed boundary and is not ensured to run properly at its current place. Consider upgrading the VPA maxAllowed
        CPU core value if the host has enough CPU cores.
      summary: Prometheus needs more CPU.
  {{- end }}

  {{- if and $root.Values.alertmanagers (gt (len $root.Values.alertmanagers) 0) }}
  - alert: PrometheusNotConnectedToAlertmanagers
    # Without max_over_time, failed scrapes could create false negatives, see
    # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
    expr: |
      max_over_time(prometheus_notifications_alertmanagers_discovered{prometheus="{{ include "prometheus.name" . }}"}[5m]) < 1
    for: 10m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` lost connection to all Alertmanagers.
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` lost connection
        to all configured Alertmanagers. Alerting is unavailable.
      summary: Prometheus not connected to any Alertmanager.

  - alert: PrometheusErrorSendingAlerts
    expr: |
      (
        rate(prometheus_notifications_errors_total{prometheus="{{ include "prometheus.name" . }}"}[5m])
      /
        rate(prometheus_notifications_sent_total{prometheus="{{ include "prometheus.name" . }}"}[5m])
      )
      * 100
      > 1
    for: 10m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` fails to send alerts.
    annotations:
      description: |
        `{{`{{ printf "%.1f" $value }}`}}%` errors while sending 
        alerts from Prometheus `{{`{{ $labels.prometheus }}`}}`
        to Alertmanager {{`{{ $labels.alertmanager }}`}}.
      summary: Prometheus has encountered more than 1% errors sending alerts to a specific Alertmanager.

  - alert: PrometheusHighAlertRate
    expr: |
      avg by (prometheus) (rate(prometheus_notifications_sent_total{prometheus="{{ include "prometheus.name" . }}"}[5m]) > 50)
    for: 5m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` sends a high number of alerts.
      playbook: docs/support/playbook/prometheus/high_alert_rate
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` sends
        a high number of alerts to alert managers.
        <https://{{ include "prometheus.externalURL" . }}/graph?g0.expr={{ urlquery `topk(5, count by (alertname) (ALERTS))` }}|Affected alerts >
      summary: Prometheus has encountered a high number of alerts sent to alert managers.

  - alert: PrometheusNotificationQueueRunningFull
    # Without min_over_time, failed scrapes could create false negatives, see
    # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
    expr: |
      (
        predict_linear(prometheus_notifications_queue_length{prometheus="{{ include "prometheus.name" . }}"}[5m], 60 * 30)
      >
        min_over_time(prometheus_notifications_queue_capacity{prometheus="{{ include "prometheus.name" . }}"}[5m])
      )
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` alert notification queue predicted to run full in less than 30m.
    annotations:
      description: |
        Alert notification queue of Prometheus `{{`{{ $labels.prometheus }}`}}`
        is running full.
      summary: Prometheus alert notification queue predicted to run full in less than 30m.
  {{- end }}

  {{- if $root.Values.remoteWriteTargets }}
  - alert: PrometheusRemoteWriteDown
    expr: |
      (
        (rate(prometheus_remote_storage_samples_failed_total{prometheus="{{ include "prometheus.name" . }}"}[5m]))
      /
        (rate(prometheus_remote_storage_samples_total{prometheus="{{ include "prometheus.name" . }}"}[5m]))
      )
      * 100
      > 1
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      no_alert_on_absence: "true"
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` fails to send samples to `{{`{{ $labels.url }}`}}`.
      playbook: docs/support/playbook/prometheus/remote_write
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` fails to send samples
        to `{{`{{ $labels.remote_name }}`}}`. It could be a problem of the
        backend not being available or expired certificates. Check pod logs.
      summary: Prometheus fails to send samples to remote storage.

  - alert: PrometheusRemoteWriteBehind
    # Without max_over_time, failed scrapes could create false negatives, see
    # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
    expr: |
      (
        max_over_time(prometheus_remote_storage_highest_timestamp_in_seconds{prometheus="{{ include "prometheus.name" . }}"}[5m])
      - ignoring(remote_name, url) group_right
        max_over_time(prometheus_remote_storage_queue_highest_sent_timestamp_seconds{prometheus="{{ include "prometheus.name" . }}"}[5m])
      )
      > 120
    for: 15m
    labels:
      service: {{ default "metrics" $root.Values.alerts.service }}
      support_group: {{ default "observability" $root.Values.alerts.support_group }}
      severity: warning
      no_alert_on_absence: "true"
      meta: Prometheus `{{`{{ $labels.prometheus }}`}}` remote write is behind.
      playbook: docs/support/playbook/prometheus/remote_write
    annotations:
      description: |
        Prometheus `{{`{{ $labels.prometheus }}`}}` remote write is behind for `{{`{{ $labels.url }}`}}`.
      summary: Prometheus remote write is behind.
  {{- end }}
