- name: health.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}RabbitMQNotReady
    expr: (kube_pod_status_ready_normalized{condition="true", pod=~"{{ include "fullname" . }}.*", pod!~"{{ include "fullname" . }}-notifications.*"} < 1)
    for: 10m
    labels:
      severity: critical
      context: availability
      service: {{ include "alerts.service" . }}
      dashboard: rabbitmq
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/devops/alert/rabbitmq/'
    annotations:
      description: {{ include "fullname" . }} is not ready for 10 minutes.
      summary: {{ include "fullname" . }} is not ready for 10 minutes. Please check the pod.
