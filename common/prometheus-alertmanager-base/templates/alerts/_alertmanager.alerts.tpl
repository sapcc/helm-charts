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

  - alert: AlertmanagerClusterPrunedMessages
    expr: alertmanager_cluster_messages_pruned_total
    for: 10m
    labels:
      context: availability
      service: alertmanager
      severity: warning
      tier: {{ include "alerts.tier" . }}
      playbook: 'docs/support/playbook/prometheus/alertmanager_cluster_failures.html'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failing sending notifications.'
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} fails to synchronize with other Alertmanagers of the HA cluster. This can cause duplicate notifications.'
      summary: Alertmanager in HA cluster fail to synchronize.

  - alert: AlertmanagerInvalidAlerts
    expr: rate(alertmanager_alerts_invalid_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) > 0
    for: 5m
    labels:
      context: availability
      service: alertmanager
      severity: info
      tier: {{ include "alerts.tier" . }}
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} receives invalid alerts.'
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} receives invalid alerts and discards them. Check the Alertmanagers log for details.'
      summary: Alertmanager receives invalid alerts.


