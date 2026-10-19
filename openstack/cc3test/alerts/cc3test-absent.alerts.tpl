groups:
- name: cc3test-absent.alerts
  rules:
  - alert: CC3TestScrapeDown
    expr: up{job=~'prometheus-statsd-exporter(.*)'} == 0
    for: 30m
    labels:
      severity: critical
      service: cc3test
      meta: "Metrics scrape job {{`{{ $labels.job }}`}} is down for more than 30 minutes"
    annotations:
      description: "Metrics scrape job {{`{{ $labels.job }}`}} is down for more than 30 minutes"
      summary: "Scrape job {{`{{ $labels.job }}`}}} is down"

  - alert: CC3TestCountersAbsent
    expr: absent(cc3test_total{when='call'}) == 1
    for: 30m
    labels:
      severity: critical
      service: cc3test
      meta: "cc3test counters for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
    annotations:
      description: "cc3test counters for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
      summary: "cc3test counters for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent"

  - alert: CC3TestMetricsAbsent
    expr: absent(cc3test_status{type!~'(.+)purge$|purge', phase="call"}) == 1
    for: 30m
    labels:
      severity: warning
      service: cc3test
      meta: "cc3test metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
    annotations:
      description: "cc3test metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
      summary: "cc3test metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent"

  - alert: CC3TestApiMetricsAbsent
    expr: absent(cc3test_status{type="api", phase="call"}) == 1
    for: 1h
    labels:
      severity: critical
      service: cc3test
      support_group: observability
      playbook: "docs/support/playbook/cc3test/alerts/cc3test-alert-metrics-absent/"
      meta: "cc3test api metrics (type=api/phase=call) are absent for more than 1 hour"
    annotations:
      description: "cc3test api metrics (type=api/phase=call) are absent for more than 1 hour - api tests are not reporting results"
      summary: "cc3test api metrics are absent"

  - alert: CC3TestPurgeMetricsAbsent
    expr: absent(cc3test_status{type=~'(.+)purge$|purge', phase="call"}) == 1
    for: 30m
    labels:
      severity: warning
      service: cc3test
      meta: "purge metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
    annotations:
      description: "purge metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent for more than 30 minutes"
      summary: "purge metrics for {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}} are absent"
