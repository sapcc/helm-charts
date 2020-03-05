groups:
- name: {{ include "alerts.service" . | title }}-rabbitmq.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCUnackTotal
    expr: sum(rabbitmq_queue_messages_unacknowledged{app=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app) > {{ .Values.alerts.rabbit_queue_length | default 1000 }}
    labels:
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service:  {{ include "alerts.service" . }}
      context: '{{`{{ $labels.app }}`}}'
      dashboard: rabbitmq
      meta: '{{`{{ $labels.app }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} unacknowledged messages.'
      playbook: 'docs/devops/alert/rabbitmq/'
    annotations:
      description: 'RPC Messages are not being collected. {{`{{ $labels.app }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} unacknowledged messages.'
      summary: 'RPC messages are not being collected.'

  - alert: {{ include "alerts.service" . | title }}RabbitMQRPCReadyTotal
    expr: sum(rabbitmq_queue_messages_ready{app=~"{{ include "alerts.service" . }}-rabbitmq"}) by (app) > {{ .Values.alerts.rabbit_queue_length | default 1000 }}
    labels:
      for: {{ .Values.alerts.ready_total_wait_for | default "1m" }}
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      service: {{ include "alerts.service" . }}
      context: '{{`{{ $labels.app }}`}}'
      dashboard: rabbitmq
      meta: 'RPC Messages are not being collected. {{`{{ $labels.app }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} rpc messages waiting.'
      playbook: 'docs/devops/alert/rabbitmq/'
    annotations:
      description: 'RPC Messages are not being collected. {{`{{ $labels.app }}`}} has over {{ .Values.alerts.rabbit_queue_length | default 1000 }} rpc messages waiting.'
      summary: 'RPC messages are not being collected.'
