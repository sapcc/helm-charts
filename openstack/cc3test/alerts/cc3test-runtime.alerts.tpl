groups:
- name: cc3test-runtime.alerts
  rules:
  - alert: CC3TestApiTestsNotRunning
    expr: sum without (pod, instance) (increase(cc3test_total{type='api', when='call'}[20m])) == 0
    for: 30m
    labels:
      severity: warning
      service: cc3test
      context: "{{`{{ $labels.service }}`}}"
      dashboard: cc3test-api-status
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status"
      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
    annotations:
      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

  - alert: CC3TestApiTestsSetupNotRunning
    expr: sum without (pod, instance) (increase(cc3test_total{type='api', when='setup'}[20m])) == 0
    for: 30m
    labels:
      severity: info
      service: cc3test
      context: "{{`{{ $labels.service }}`}}"
      dashboard: cc3test-api-status
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status"
      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
    annotations:
      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

  - alert: CC3TestDatapathTestsNotRunning
    expr: sum without (pod, instance) (increase(cc3test_total{type='datapath', when='call'}[20m])) == 0
    for: 30m
    labels:
      severity: warning
      service: cc3test
      context: "{{`{{ $labels.service }}`}}"
      dashboard: cc3test-datapath-status
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-datapath-status"
      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
    annotations:
      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

  - alert: CC3TestDatapathTestsSetupNotRunning
    expr: sum without (pod, instance) (increase(cc3test_total{type='datapath', when='setup'}[20m])) == 0
    for: 30m
    labels:
      severity: info
      service: cc3test
      context: "{{`{{ $labels.service }}`}}"
      dashboard: cc3test-datapath-status
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-datapath-status"
      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
    annotations:
      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 30 minutes"
      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

#  - alert: CC3TestCanaryTestsNotRunning
#    expr: sum without (pod, instance) (increase(cc3test_total{type!~'api|datapath|(.+)purge$|purge|certificate|baremetal_and_regression|(.+)allhosts$', when='call'}[60m])) == 0
#    for: 120m
#    labels:
#      severity: info
#      service: cc3test
#      context: "{{`{{ $labels.service }}`}}"
#      dashboard: cc3test-api-status
#      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#    annotations:
#      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

  - alert: CC3TestCertificateTestsNotRunning
    expr: sum without (pod, instance) (increase(cc3test_total{type='certificate', when='call'}[24h])) == 0
    for: 1d
    labels:
      severity: warning
      service: cc3test
      context: "{{`{{ $labels.service }}`}}"
      dashboard: cc3test-certificate-status
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-certificate-status"
      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 1 day"
    annotations:
      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 1 day"
      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

  - alert: CC3testSAMLTestsNotRunning
    expr: |
        sum without (pod, instance) (
          increase(cc3test_total{service="keystone", name=~"TestSAML.+", when="call"}[20m])
        ) == 0
    for: 30m
    labels:
      severity: warning
      support_group: identity
      service: "{{`{{ $labels.service }}`}}"
      context: "{{`{{ $labels.service }}`}}"
      meta: "SAML cc3test tests for {{`{{ $labels.name }}`}} are not running for more than 30 minutes"
      dashboard: "cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/cc3test-api-status?var-service={{`{{ $labels.service }}`}}"
      playbook: "docs/support/playbook/keystone/alerts/saml-federation-alerts/"
      report: "cc3test/admin/object-storage/swift/containers/cc3test/objects/{{`{{ $labels.base64path }}`}}"
    annotations:
      description: "SAML cc3test tests for {{`{{ $labels.name }}`}} have not run in more than 30 minutes. SAML federation security controls (BSI SF.Fas.1/2, #1181) may not be monitored."
      summary: "SAML cc3test tests not running"

#  - alert: CC3TestPurgerNotRunning
#    expr: sum without (pod, instance) (increase(cc3test_total{type=~'(.+)purge$|purge',when='call'}[60m])) == 0
#    for: 60m
#    labels:
#      severity: warning
#      service: cc3test
#      context: "{{`{{ $labels.service }}`}}"
#      dashboard: cc3test-api-status
#      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#    annotations:
#      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"

#  - alert: CC3TestCanaryPrepNotRunning
#    expr: sum without (pod, instance) (increase(cc3test_total{type!~'api|datapath|(.+)purge$|purge', name!~'.+cert_expiry.+', when='setup'}[60m])) == 0
#    for: 60m
#    labels:
#      severity: warning
#      service: cc3test
#      context: "{{`{{ $labels.service }}`}}"
#      dashboard: cc3test-api-status
#      meta: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#    annotations:
#      description: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is not running for more than 60 minutes"
#      summary: "cc3test {{`{{ $labels.type }}`}}/{{`{{ $labels.name }}`}}/{{`{{ $labels.when }}`}} is down"
