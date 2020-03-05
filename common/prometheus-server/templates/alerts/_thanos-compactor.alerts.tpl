groups:
- name: thanos-compactor.alerts
  rules:
    - alert: ThanosCompactHalted
      expr: thanos_compactor_halted{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"} == 1
      for: 5m
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_compaction.html'
        meta: 'Thanos compaction for Prometheus {{`{{ $labels.prometheus }}`}} halted.'
      annotations:
        description: 'Thanos compaction has failed to run and now is halted for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries will be slower.'
        summary: Thanos compaction halted

    - alert: ThanosCompactCompactionsFailed
      expr: rate(prometheus_tsdb_compactions_failed_total{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_compaction.html'
        meta: 'Thanos compact is failing compaction for Prometheus {{`{{ $labels.prometheus }}`}}'
      annotations:
        description: 'Thanos Compact is failing compaction for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries will be slower.'
        summary: Thanos Compact is failing

    - alert: ThanosCompactBucketOperationsFailed
      expr: rate(thanos_objstore_bucket_operation_failures_total{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"}[5m]) > 0
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_compaction.html'
        meta: 'Thanos Compact bucket operations are failing for Prometheus {{`{{ $labels.prometheus }}`}}'
      annotations:
        description: 'Thanos Compact bucket operations are failing for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries will be slower.'
        summary: Prometheus compact bucket operations failing

    - alert: ThanosCompactNotRunIn24Hours
      expr: (time() - max(thanos_objstore_bucket_last_successful_upload_time{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"}) ) /60/60 > 24
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_compaction.html'
        meta: 'Thanos compaction not run in 24h for Prometheus {{`{{ $labels.prometheus }}`}}.'
      annotations:
        description: 'Thanos Compaction has not been run in 24 hours for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries will be slower.'
        summary: Thanos compaction not run in 24 hours

    - alert: ThanosCompactCompactionIsNotRunning
      expr: up{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"} == 0 or absent({app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"})
      for: 5m
      labels:
        context: thanos
        service: prometheus
        severity: info
        tier: {{ include "alerts.tier" . }}
        playbook: 'docs/support/playbook/prometheus/thanos_compaction.html'
        meta: 'Thanos compaction not running for Prometheus {{`{{ $labels.prometheus }}`}}.'
      annotations:
        description: 'Thanos Compaction is not running for Prometheus {{`{{ $labels.prometheus }}`}}. Long term storage queries will be slower.'
        summary: Thanos compaction not running

    - alert: ThanosCompactMultipleCompactionsAreRunning
      expr: sum(up{app="thanos-compactor", prometheus="{{ include "prometheus.name" . }}"}) > 1
      for: 5m
      labels:
        context: thanos
        service: prometheus
        severity: warning
        tier: {{ include "alerts.tier" . }}
        meta: 'Multiple Thanos compactors running for Prometheus {{`{{ $labels.prometheus }}`}}.'
      annotations:
        description: 'Multiple replicas of Thanos compaction running for Prometheus {{`{{ $labels.prometheus }}`}}. Metrics in long term storage may be corrupted.'
        summary: Multiple Thanos compactors running
