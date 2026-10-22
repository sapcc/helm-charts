groups:
- name: cc3test-portunus.alerts
  rules:
  - alert: CloudHSMApiDown
    expr: |
        cc3test_status{service="portunus", type="api", name=~"TestPortunusAPI_.+", phase="call"} == 0
    for: 30m
    labels:
      severity: info
      support_group: trust
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.service }}`}}"
      meta: "CloudHSM API is down"
      dashboard: "cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "CloudHSM API is down: {{`{{ $labels.name }}`}}"
      summary: "CloudHSM API is down"

  - alert: CloudHSMCreationFailed
    expr: |
        cc3test_status{service="portunus", type="api", name=~"TestPortunusCloudHSM_create_cloudhsm.+", phase="call"} == 0
    for: 12h
    labels:
      severity: info
      support_group: trust
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.service }}`}}"
      meta: "CloudHSM Creation Failed"
      dashboard: "cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "CloudHSM Creation Failed: {{`{{ $labels.name }}`}}"
      summary: "CloudHSM Creation Failed"

  - alert: CloudHSMDeletionFailed
    expr: |
        cc3test_status{service="portunus", type="api", name=~"TestPortunusCloudHSM_purge_cloudhsm.+", phase="call"} == 0
    for: 1h
    labels:
      severity: info
      support_group: trust
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.service }}`}}"
      meta: "CloudHSM Delete Failed"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "CloudHSM Delete Failed: {{`{{ $labels.name }}`}}"
      summary: "CloudHSM Delete Failed"