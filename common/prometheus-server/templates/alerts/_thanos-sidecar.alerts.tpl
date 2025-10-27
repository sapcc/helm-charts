{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-sidecar.alerts
  rules:
    - alert: ThanosSidecarBucketOperationsFailed
      expr: |
        sum by (prometheus, instance) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*sidecar.*", prometheus="{{ include "prometheus.name" . }}"}[5m])) > 0
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Sidecar bucket operations are failing for Prometheus `{{`{{ $labels.prometheus }}`}}`
        playbook: docs/support/playbook/prometheus/thanos_sidecar
        no_alert_on_absence: "true"
      annotations:
        description: |
          Thanos Sidecar bucket operations are failing for
          Prometheus `{{`{{ $labels.prometheus }}`}}`.
          Metrics data will be lost if not fixed in 24h.
        summary: Thanos Sidecar bucket operations are failing.

    - alert: ThanosSidecarNoConnectionToStartedPrometheus
      expr: |
        thanos_sidecar_prometheus_up{job=~".*thanos.*sidecar.*", prometheus="{{ include "prometheus.name" . }}"} == 0
        AND on (namespace, pod)
        prometheus_tsdb_data_replay_duration_seconds != 0
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Thanos Sidecar cannot access Prometheus `{{`{{ $labels.prometheus }}`}}`'.
        playbook: docs/support/playbook/prometheus/thanos_sidecar
      annotations:
        description: |
          Thanos Sidecar cannot access Prometheus `{{`{{ $labels.prometheus }}`}}`',
          even though Prometheus seems healthy and has reloaded WAL.
        summary: Thanos Sidecar cannot access Prometheus, even though Prometheus seems healthy and has reloaded WAL.
