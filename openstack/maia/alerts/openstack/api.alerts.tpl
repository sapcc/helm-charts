groups:
- name: maia.alerts
  rules:
  - alert: OpenstackMaiaExportersLag
    expr: predict_linear(scrape_duration_seconds{service="metrics"}[1h], 7 * 24 * 60 * 60) > 60
    for: 1h
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: latency
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: warning
      support_group: observability
      tier: os
      meta: 'Maia exporters lagging'
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: "Maia exporter {{`{{ $labels.component }}`}} is predicted to break the 60s limit for data collection 7 days from now."
      summary: Maia exporters lagging

  - alert: OpenstackMaiaResponsiveness
    expr: histogram_quantile(0.99, sum by (le, handler, component) (rate(maia_request_duration_seconds_bucket{component="maia",namespace="maia"}[5m]))) > 3
    for: 1h
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: latency
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: warning
      tier: os
      support_group: observability
      meta: 'Maia API lags'
      no_alert_on_absence: "true"
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: Maia API does not fulfill the responsiveness goals (99% responses within 3 seconds)
      summary: Maia API lags

  - alert: OpenstackMaiaPrometheusAvail
    expr: rate(maia_tsdb_errors_count{namespace="maia"}[10m]) > 0
    for: 15m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: availability
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: warning
      tier: os
      support_group: observability
      meta: 'Maia availability affected by Prometheus issues'
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: Maia API is affected by errors when accessing the underlying Prometheus installation
      summary: Maia availability affected by Prometheus issues

  - alert: OpenstackMaiaKeystoneAvail
    expr: rate(maia_logon_errors_count{namespace="maia"}[5m]) > 0
    for: 15m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: availability
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: warning
      tier: os
      support_group: observability
      meta: 'Maia availability affected by Keystone issues'
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: Maia API is affected by errors when accessing Keystone
      summary: Maia availability affected by Keystone issues

  - alert: OpenstackMaiaUp
    expr: up{component="maia",namespace="maia"} < 1
    for: 10m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: availability
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: critical
      tier: os
      support_group: observability
      meta: "Maia Is not available"
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: Maia monitoring endpoint is down => Maia is down
      summary: Maia is not available

  - alert: OpenstackMaiaHighAuthFailureRate
    expr: sum by (component, namespace) (rate(maia_logon_failures_count{component="maia",namespace="maia"}[5m])) > 5
    for: 15m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: availability
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: info
      tier: os
      support_group: observability
      meta: "High Maia authentication failure rate"
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: "Maia is seeing {{`{{ $value | humanize }}`}} failed authentication attempts/s (threshold: 5/s) sustained for 15 minutes. This may indicate brute-force attempts, a broken automation, or a credential rotation issue."
      summary: High rate of Maia authentication failures

  - alert: OpenstackMaiaHighInflightRequests
    expr: sum by (component, namespace) (maia_requests_inflight{component="maia",namespace="maia"}) > 100
    for: 5m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: latency
      dashboard: maia-overview
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/maia-overview"
      service: maia
      severity: info
      tier: os
      support_group: observability
      meta: "High number of concurrent Maia requests"
      playbook: 'docs/support/playbook/maia/alerts/cc3test-alert-api'
    annotations:
      description: "Maia has {{`{{ $value }}`}} requests in-flight (threshold: 100) for 5 minutes. CPU/memory pressure may be elevated; check for runaway automation or long-running query loops."
      summary: High number of concurrent requests in Maia
