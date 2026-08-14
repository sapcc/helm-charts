groups:
- name: cc3test-blockstorage.alerts
  rules:
  - alert: OpenstackCinderApiDown
    expr: |
        cc3test_status{service="cinder",
            type="api",
            phase="call"
        } == 0
    for: 16m
    labels:
      severity: critical
      support_group: compute-storage-api
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.type }}`}}"
      meta: "Openstack Cinder API is down"
      dashboard: "cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-api/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Cinder API is down"
      summary: "Cinder API is down"

  - alert: OpenstackCinderApiFlapping
    expr: |
        changes(cc3test_status{service="cinder",
            type="api",
            phase="call"
        }[30m]) > 8
    labels:
      severity: warning
      support_group: compute-storage-api
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.type }}`}}"
      meta: "Openstack Cinder API is flapping"
      dashboard: "cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-api/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Flapping Cinder API"
      summary: "Flapping Cinder API"

  - alert: OpenstackCinderCreateVolumeAvzDown
    expr: |
        last_over_time(cc3test_status{service="cinder",
        name=~"^TestVolume_create.+",phase="call"}[60m]) == 0
    for: 30m
    labels:
      severity: warning
      support_group: compute-storage-api
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.type }}`}}"
      meta: "Cinder create volume test fails"
      dashboard: "cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-create-volume/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Cinder create volume test fails: {{`{{ $labels.name }}`}}"
      summary: "Cinder create volume test fails: {{`{{ $labels.name }}`}}"

  - alert: OpenstackCinderCreateVolumeShardDown
    expr: |
        last_over_time(cc3test_status{service="cinder",
        name=~"TestVolume_attach_to_server.+",phase="call"}[120m]) == 0
    for: 120m
    labels:
      severity: warning
      support_group: compute-storage-api
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.type }}`}}"
      meta: "Cinder create volume test fails"
      dashboard: "cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-create-volume-shard/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Cinder create volume test fails: {{`{{ $labels.name }}`}}"
      summary: "Cinder create volume test fails: {{`{{ $labels.name }}`}}"

  - alert: OpenstackCinderCreateSnapshot
    expr: |
        last_over_time(cc3test_status{service="cinder",
        name=~"TestSnapshot_create_snapshot.+",phase="call"}[1h]) == 0
    for: 30m
    labels:
      severity: info
      support_group: compute-storage-api
      tier: os
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.type }}`}}"
      meta: "Cinder create snapshot test fails"
      dashboard: "cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-create-snapshot/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Cinder create snapshot test fails - please ignore: {{`{{ $labels.name }}`}}"
      summary: "Cinder create snapshot test fails - please ignore: {{`{{ $labels.name }}`}}"


  - alert: OpenstackCinderKVMVolumeAttachFailed
    expr: |
        last_over_time(cc3test_status{service="nova_kvm", 
        name=~"TestComputeKVMServer_attach_server.+",phase="call"}[1h]) == 0
    for: 2h
    labels:
      severity: critical
      support_group: compute-storage-api
      tier: os
      service: cinder
      context: cinder
      meta: "Openstack Cinder KVM Canary: {{`{{ $labels.name }}`}} is down, see report for more details"
      dashboard: cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-kvm-attach-volume/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Openstack Cinder KVM Canary: {{`{{ $labels.name }}`}} is down, see report for more details"
      summary: "Openstack Cinder KVM Canary: {{`{{ $labels.name }}`}} is down, see report for more details"


  - alert: OpenstackCinderKVMVolumeAttachFlapping
    expr: changes(cc3test_status{service="nova_kvm", 
        name=~"TestComputeKVMServer_attach_server.+",phase="call"}[2h]) > 8
    labels:
      severity: warning
      support_group: compute-storage-api
      tier: os
      service: cinder
      context: cinder
      meta: "Openstack Cinder KVM Canary is flapping for 2 hours, see last three reports for more details"
      dashboard: cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-bb-vc-canary-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/cinder/alerts/cc3test-alert-kvm-attach-volume/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "Openstack Cinder KVM Canary is flapping for 2 hours, see last three reports for more details"
      summary: "Openstack Cinder KVM Canary is flapping for 2 hours, see last three reports for more details"
