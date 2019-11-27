groups:
- name: alertmanager.alerts
  rules:
  - alert: AlertmanagerFailedConfigReload
    expr: alertmanager_config_last_reload_successful{alertmanager="{{ include "alertmanager.name" . }}"} == 0
    for: 5m
    labels:
      context: availability
      service: alertmanager
      severity: critical
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/failed_config_reload.html'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to load it`s configuration.'
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to load it`s configuration. Alertmanager cannot start with a malformed configuration.'
      summary: Alertmanager configuration reload has failed

  - alert: AlertmanagerNotificationsFailing
    expr: rate(alertmanager_notifications_failed_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) > 0
    for: 1m
    labels:
      context: availability
      service: alertmanager
      severity: warning
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/alertmanager_failed_notifications.html'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failing sending notifications.'
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is failing to send notifications for integration {{`{{ $labels.integration }}`}}.'
      summary: Alertmanager failing to send notifications

