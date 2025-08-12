groups:
- name: {{ include "alerts.service" . | title }}-rabbitmq.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCUnackTotal
    expr: sum(rabbitmq_queue_messages_unacked{app_kubernetes_io_instance=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app_kubernetes_io_instance) > {{ .Values.alerts.rabbit_queue_length | default 1000 }}
    for: {{ .Values.alerts.unacknowledged_total_wait_for | default "1m" }}
    labels:
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      service:  {{ include "alerts.service" . }}
      context: '{{`{{ $labels.app_kubernetes_io_instance }}`}}'
      dashboard: rabbitmq
      meta: '{{`{{ $labels.app_kubernetes_io_instance }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} unacknowledged messages.'
      playbook: 'https://operations.global.cloud.sap/docs/devops/alert/rabbitmq/'
    annotations:
      description: 'RPC Messages are not being collected. {{`{{ $labels.app_kubernetes_io_instance }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} unacknowledged messages.'
      summary: 'RPC messages are not being collected.'

  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCReadyTotal
    expr: sum(rabbitmq_queue_messages_ready{app_kubernetes_io_instance=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app_kubernetes_io_instance) > {{ .Values.alerts.rabbit_queue_length | default 1000 }}
    for: {{ .Values.alerts.ready_total_wait_for | default "1m" }}
    labels:
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      service: {{ include "alerts.service" . }}
      context: '{{`{{ $labels.app_kubernetes_io_instance }}`}}'
      dashboard: rabbitmq
      meta: 'RPC Messages are not being collected. {{`{{ $labels.app_kubernetes_io_instance }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} rpc messages waiting.'
      playbook: 'https://operations.global.cloud.sap/docs/devops/alert/rabbitmq/'
    annotations:
      description: 'RPC Messages are not being collected. {{`{{ $labels.app_kubernetes_io_instance }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} rpc messages waiting.'
      summary: 'RPC messages are not being collected.'
