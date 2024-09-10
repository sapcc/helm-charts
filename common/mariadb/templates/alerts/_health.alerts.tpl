- name: health.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDBNotReady
    expr: (sum(kube_pod_status_ready_normalized{condition="true", pod=~"{{ include "fullName" . }}.*", pod!~"{{ include "fullName" . }}-backup.*", pod!~"{{ include "fullName" . }}-verification.*"}) < 1)
    for: 10m
    labels:
      context: availability
      service: {{ include "alerts.service" . }}
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      playbook: 'docs/support/playbook/db_crashloop'
    annotations:
      description: No {{ include "fullName" . }} database is ready for 10 minutes.
      summary: No {{ include "fullName" . }} is ready for 10 minutes. Please check the pod.
