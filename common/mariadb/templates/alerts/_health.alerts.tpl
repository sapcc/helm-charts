- name: health.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDBNotReady
    expr: (kube_pod_status_ready_normalized{condition="true", pod=~"{{ include "fullName" . }}.*", pod!~"{{ include "fullName" . }}-backup.*", pod!~"{{ include "fullName" . }}-verification.*"} < 1)
    for: 5m
    labels:
      context: availability
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/db_crashloop.html'
    annotations:
      description: {{ include "fullName" . }} database is not ready for 5 minutes.
      summary: {{ include "fullName" . }} is not ready for 5 minutes.
