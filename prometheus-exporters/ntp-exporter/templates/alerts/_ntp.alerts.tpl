groups:
- name: ntp.alerts
  rules:
    - alert: KubernetesNodeClockDrift
      expr: abs(ntp_drift_seconds) > 0.3
      for: 1h
      labels:
        tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
        service: node
        severity: warning
        context: availability
        meta: "Clock drift on {{`{{ $labels.instance }}`}}"
        dashboard: nodes?var-server={{`{{$labels.instance}}`}}
      annotations:
        summary: High NTP drift
        description: The clock on node {{`{{ $labels.instance }}`}} is more than 300ms apart from its NTP server. This can cause service degradation.
