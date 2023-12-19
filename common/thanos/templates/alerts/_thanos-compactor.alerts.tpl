{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
groups:
- name: thanos-compactor.alerts
  rules:
    - alert: ThanosCompactMultipleRunning
      expr: sum by (thanos) (up{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}) > 1
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        meta: Multiple Thanos compactors running for `{{`{{ $labels.thanos }}`}}`.
      annotations:
        description: |
          No more than one Thanos Compact instance should be running
          at once for `{{`{{ $labels.thanos }}`}}`.
          Metrics in long term storage may be corrupted.
        summary: Thanos Compact has multiple instances running.

    - alert: ThanosCompactHalted
      expr: thanos_compact_halted{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"} == 1
      for: 5m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        meta: Thanos Compact `{{`{{ $labels.thanos }}`}}` has failed to run and is now halted.
        playbook: 'docs/support/playbook/prometheus/thanos_compaction/#thanos-compact-halted'
      annotations:
        description: |
          Thanos Compact `{{`{{ $labels.thanos }}`}}` has
          failed to run and is now halted.
          Long term storage queries will be slower.
        summary: Thanos Compact has failed to run and is now halted.

    - alert: ThanosCompactHighCompactionFailures
      expr: |
        (
          sum by (thanos) (rate(thanos_compact_group_compactions_failures_total{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_compact_group_compactions_total{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        playbook: 'docs/support/playbook/prometheus/thanos_compaction/#thanos-component-has-disappeared'
        meta: Thanos Compact `{{`{{ $labels.thanos }}`}}` is failing to execute compactions.
      annotations:
        description: |
          Thanos Compact `{{`{{ $labels.thanos }}`}}` is failing to execute
          `{{`{{ $value | humanize }}`}}%`of compactions.
          Long term storage queries will be slower.
        summary: Thanos Compact is failing to execute compactions.

    - alert: ThanosCompactBucketHighOperationFailures
      expr: |
        (
          sum by (thanos) (rate(thanos_objstore_bucket_operation_failures_total{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        /
          sum by (thanos) (rate(thanos_objstore_bucket_operations_total{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        playbook: 'docs/support/playbook/prometheus/thanos_compaction'
        meta: Thanos Compact `{{`{{ $labels.thanos }}`}}` bucket is having a high number of operation failures.
      annotations:
        description: |
          Thanos Compact `{{`{{ $labels.thanos }}`}}` Bucket is failing
          to execute `{{`{{ $value | humanize }}`}}%` operations.
          Long term storage queries will be slower.
        summary: Thanos Compact Bucket is having a high number of operation failures.

    - alert: ThanosCompactHasNotRun
      expr: (time() - max by (thanos) (max_over_time(thanos_objstore_bucket_last_successful_upload_time{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"}[24h])))
        / 60 / 60 > 24
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        playbook: 'docs/support/playbook/prometheus/thanos_compaction'
        meta: Thanos Compact `{{`{{ $labels.thanos }}`}}` has not uploaded anything for last 24 hours.
      annotations:
        description: |
          Thanos Compact `{{`{{ $labels.thanos }}`}}` has not
          uploaded anything for 24 hours.
          Long term storage queries will be slower.
        summary: Thanos Compact has not uploaded anything for last 24 hours.

    - alert: ThanosCompactIsDown
      expr: up{job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"} == 0 or absent({job=~".*thanos.*compact.*", thanos="{{ include "thanos.name" . }}"})
      for: 15m
      labels:
        no_alert_on_absence: "true" # because the expression already checks for absence
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: warning
        playbook: docs/support/playbook/prometheus/thanos_compaction
        meta: Thanos Compact `{{`{{ $labels.thanos }}`}}` has disappeared.
      annotations:
        description: |
          Thanos Compact `{{`{{ $labels.thanos }}`}}` has disappeared.
          Prometheus target for the component cannot be discovered.
        summary: Thanos component has disappeared.

    - alert: ThanosCompactSpawningManyPods 
      expr: count by (region, namespace) (kube_pod_info{pod=~"thanos-{{ include "thanos.name" . }}-compactor-*.+"}) > 100 
      for: 15m
      labels:
        service: {{ default "metrics" $root.Values.alerts.service }}
        support_group: {{ default "observability" $root.Values.alerts.support_group }}
        severity: info
        playbook: docs/support/playbook/prometheus/thanos_compaction/#thanos-compact-halted
        meta: Thanos compact in `{{`{{ $labels.namespace }}`}}` is spawning loads of pods due to compaction problems.
      annotations:
        description: |
          Some compactor is having a problem in `{{`{{ $labels.namespace }}`}}`. Check namespace for a big amount of compactor pods, clean it and fix the block storage issue.
        summary: Thanos compact is spawning loads of pods due to compaction problems.
