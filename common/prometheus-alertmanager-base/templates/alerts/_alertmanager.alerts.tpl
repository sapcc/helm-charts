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
      playbook: 'docs/support/playbook/prometheus/failed_config_reload'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to load it`s configuration.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to load it`s configuration. Alertmanager cannot start with a malformed configuration.'
      summary: Alertmanager configuration reload has failed

  - alert: AlertmanagerNotificationsFailing
    expr: rate(alertmanager_notifications_failed_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) > 0
    for: 10m
    labels:
      context: availability
      service: alerting
      severity: info
      playbook: 'docs/support/playbook/prometheus/alertmanager_failed_notifications'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failing sending notifications.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is failing to send notifications for integration {{`{{ $labels.integration }}`}}.'
      summary: Alertmanager failing to send notifications

  - alert: AlertmanagerClusterMessagesPruned
    expr: rate(alertmanager_cluster_messages_pruned_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) > 0
    for: 10m
    labels:
      context: availability
      service: alertmanager
      severity: warning
      playbook: 'docs/support/playbook/prometheus/alertmanager_alerts/cluster-messages-pruned'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is pruning the cluster message queue.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is pruning the message queue and cluster messages are dropped.'
      summary: Alertmanager in HA cluster fails to synchronize

  - alert: AlertmanagerClusterMessagesQueued
    expr: alertmanager_cluster_messages_queued{alertmanager="{{ include "alertmanager.name" . }}"} != 0
    for: 15m
    labels:
      context: availability
      service: alerting
      severity: info
      playbook: 'docs/support/playbook/prometheus/alertmanager_alerts/cluster-messages-queued'
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is queing cluster messages.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} is queing cluster messages. This can cause dropping messages because too many are queued.'
      summary: Alertmanager in HA cluster fails to synchronize

  - alert: AlertmanagerInvalidAlerts
    expr: rate(alertmanager_alerts_invalid_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) > 0
    for: 5m
    labels:
      context: availability
      service: alerting
      severity: info
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} receives invalid alerts.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} receives invalid alerts and discards them. Check the Alertmanagers log for details.'
      summary: Alertmanager receives invalid alerts.

  - alert: AlertmanagerClusterHealthDegraded
    expr: alertmanager_cluster_health_score{alertmanager="{{ include "alertmanager.name" . }}"} != 0
    for: 15m
    labels:
      context: availability
      service: alerting
      severity: info
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} cluster health is degraded.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} cluster has problems. Check AM logs.'
      summary: Alertmanager cluster health degraded.

  - alert: AlertmanagerPeerReconnectFailed
    expr: rate(alertmanager_cluster_reconnections_failed_total{alertmanager="{{ include "alertmanager.name" . }}"}[5m]) != 0
    for: 15m
    labels:
      context: availability
      service: alerting
      severity: info
      meta: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to reconnect to peer.'
      support_group: {{ include "alerts.support_group" . }}
    annotations:
      description: 'Alertmanager {{`{{ $labels.alertmanager }}`}} failed to reconnect to its peer. Check AM logs.'
      summary: Alertmanager failed to reconnect to peer. 
