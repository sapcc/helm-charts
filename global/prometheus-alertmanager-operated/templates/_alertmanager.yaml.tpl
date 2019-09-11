global:
  resolve_timeout: 16m

templates:
  - /etc/alertmanager/configmaps/notification-templates/*.tmpl

inhibit_rules:
  # Alerts with higher severity inhibit less severe alerts that fire in the same region, cluster, context.
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
  receiver: 'web.hook'


receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
