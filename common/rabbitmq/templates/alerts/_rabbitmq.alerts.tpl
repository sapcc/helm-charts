groups:
- name: {{ include "alerts.service" . | title }}-rabbitmq.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCUnackTotal
    expr: sum(rabbitmq_queue_messages_unacknowledged{app=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app) > 1000
    labels:
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service:  {{ include "alerts.service" . }}
      context: '{{`{{ $labels.service }}`}}'
      dashboard: rabbitmq
      meta: '{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 1000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}.'
      playbook: 'docs/devops/alert/rabbitmq/#{{`{{ $labels.check }}`}}'
    annotations:
      description: '{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} RPC Messages are not being collected.
        {{`{{ $labels.check }}`}} has over 1000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}.'
      summary: 'RPC messages are not being collected.'

  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCReadyTotal
    expr: sum(rabbitmq_queue_messages_ready{app=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app) > 1000
    labels:
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service: {{ include "alerts.service" . }}
      context: '{{`{{ $labels.service }}`}}'
      dashboard: rabbitmq
      meta: '{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} RPC Messages are not being collected. {{`{{ $labels.check }}`}} has over 1000 rpc messages waiting in {{`{{ $labels.kubernetes_name }}`}}.'
      playbook: 'docs/devops/alert/rabbitmq/#{{`{{ $labels.check }}`}}'
    annotations:
      description: '{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} RPC Messages are not being collected.
        {{`{{ $labels.check }}`}} has over 1000 rpc messages waiting in {{`{{ $labels.kubernetes_name }}`}}.'
      summary: 'RPC messages are not being collected.'
