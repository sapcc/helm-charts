groups:
- name: certificate.alerts
  rules:
  - alert: CertificateExpiresIn30Days
    expr: (secrets_exporter_certificate_not_after - time()) / 60 / 60 / 24 <= 30
    for: 1h
    labels:
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      context: availability
      service: certificates
      severity: info
    annotations:
      description: The certificate for {{`{{ $labels.host }}`}} expires in {{`{{ $value | humanizeDuration }}`}}. See secret {{`{{ $labels.secret }}`}}, key {{`{{ $labels.key }}`}}.
      summary: Certificate expires
