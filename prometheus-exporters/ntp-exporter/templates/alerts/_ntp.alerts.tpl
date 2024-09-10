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
        support_group: containers
      annotations:
        summary: High NTP drift
        description: The clock on node {{`{{ $labels.instance }}`}} is more than 300ms apart from its NTP server. This can cause service degradation.
    - alert: KubernetesNodeNtpMetricsDown
      expr: absent(ntp_drift_seconds)
      for: 1h
      labels:
        tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
        service: node
        severity: warning
        context: availability
        meta: "Clock drift metrics absent for {{`{{ $labels.instance }}`}}"
        dashboard: nodes?var-server={{`{{$labels.instance}}`}}
        support_group: containers
      annotations:
        summary: Clock drift metrics absent
        description: The clock drift metrics are missing for node {{`{{ $labels.instance }}`}}. Check NTP exporter pod logs and connectifity to NTP servers.
