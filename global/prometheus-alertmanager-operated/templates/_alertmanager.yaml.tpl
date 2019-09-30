global:
  resolve_timeout: 16m

templates:
  - /etc/alertmanager/configmaps/alertmanager-primary-notification-templates/*.tmpl

inhibit_rules:
  # More severe alerts mute less urgent ones.
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['region', 'alertname', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
    target_match:
      severity: 'info'
    equal: ['region', 'alertname', 'cluster']

  - source_match_re:
      severity: 'critical'
      context: '.+'
    target_match_re:
      severity: 'warning'
      context: '.+'
    equal: ['region', 'context', 'cluster']

  - source_match_re:
      severity: 'critical|warning'
      context: '.+'
    target_match_re:
      severity: 'info'
      context: '.+'
    equal: ['region', 'context', 'cluster']

route:
  group_by: ['region', 'alertname', 'cluster']
  group_wait: 1m
  group_interval: 7m
  repeat_interval: 12h
  receiver: dev-null

  routes:
    - receiver: pagerduty_api_warning
      continue: true
      match_re:
        tier: os|k8s
        severity: warning
        cluster_type: controlplane
        region: qa-de-1

receivers:
  - name: dev-null
    webhook_configs:
      - url: 'http://127.0.0.1:5001'

  - name: pagerduty_api_warning
    pagerduty_configs:
      - service_key: {{ required "pagerduty.api.serviceKey undefined" .Values.pagerduty.api.serviceKey | quote }}
        description: {{"'{{ template \"pagerduty.sapcc.description\" . }}'"}}
        component: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
        group: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
        details:
          Details: {{"'{{template \"pagerduty.sapcc.details\" . }}'"}}
          Region: {{"'{{template \"pagerduty.sapcc.region\" . }}'"}}
          Tier: {{"'{{template \"pagerduty.sapcc.tier\" . }}'"}}
          Service: {{"'{{template \"pagerduty.sapcc.service\" . }}'"}}
          Context: {{"'{{template \"pagerduty.sapcc.context\" . }}'"}}
          Fingerprint: {{"'{{template \"pagerduty.sapcc.fingerprint\" . }}'"}}
          Prometheus: {{"'{{template \"pagerduty.sapcc.prometheus\" . }}'"}}
          Dashboard: {{"'{{template \"pagerduty.sapcc.dashboard\" . }}'"}}
          Sentry: {{"'{{template \"pagerduty.sapcc.sentry\" . }}'"}}
          Playbook: {{"'{{template \"pagerduty.sapcc.playbook\" . }}'"}}
          firing: {{"'{{ template \"pagerduty.sapcc.firing\" . }}'"}}
