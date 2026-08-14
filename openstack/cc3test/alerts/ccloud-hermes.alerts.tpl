groups:
- name: cc3test-hermes.alerts
  rules:
  - alert: CCloudHermesCanaryDown
    expr: |
        max(cc3test_status{service="hermes", type="api", phase="call"} == 0) unless max(cc3test_status{service="keystone", type="api"} == 0)
    for: 16m
    labels:
      severity: critical
      support_group: observability
      tier: os
      service: hermes
      meta: "CCloud Hermes canary probe is failing"
      dashboard: "cc3test-api-status?var-service=hermes"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service=hermes"
      playbook: "docs/support/playbook/hermes/alerts/cc3test-alert-api/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "CCloud Hermes canary probe is failing"
      summary: "CCloud Hermes canary probe is failing"

  - alert: CCloudHermesCanaryFlapping
    expr: |
        changes(cc3test_status{service="hermes", type="api", phase="call"}[30m]) > 8
    labels:
      severity: warning
      support_group: observability
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      meta: "CCloud Hermes canary probe is flapping"
      dashboard: "cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/hermes/alerts/cc3test-alert-api/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "CCloud Hermes canary probe is flapping"
      summary: "CCloud Hermes canary probe is flapping"

  - alert: CCloudHermesAuditEventMissing
    expr: cc3test_status{service="hermes",name=~"TestHermes_hermes.+", phase="call"} == 0
    for: 1h
    labels:
      severity: warning
      support_group: observability
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      meta: "Hermes: {{`{{ $labels.name }}`}} missing audit events, see report for more details"
      dashboard: cc3test-canary-status?var-service={{`{{ $labels.service }}`}}
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/hermes/alerts/cc3test-alert-missing-event/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Hermes: {{`{{ $labels.name }}`}} missing audit events, see report for more details"
      summary: "Hermes: {{`{{ $labels.name }}`}} missing audit events, see report for more details"

  - alert: CCloudHermesAuditEventFlapping
    expr: changes(cc3test_status{service="hermes",name=~"TestHermes_hermes.+",phase="call"}[2h]) > 8
    labels:
      severity: info
      support_group: observability
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      meta: "Hermes: {{`{{ $labels.name }}`}} flapping audit events for 2 hours, see report for more details"
      dashboard: cc3test-canary-status?var-service={{`{{ $labels.service }}`}}
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/hermes/alerts/cc3test-alert-missing-event/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Hermes: {{`{{ $labels.name }}`}} flapping audit events for 2 hours, see report for more details"
      summary: "Hermes: {{`{{ $labels.name }}`}} flapping audit events for 2 hours, see report for more details"
