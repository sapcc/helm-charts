groups:
- name: certificate.alerts
  rules:
  - alert: X509CertificateExpiresIn30Days
    expr: (x509_cert_not_after - time()) / 60 / 60 / 24 <= 30
    for: 1h
    labels:
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      context: availability
      service: certificates
      severity: info
      support_group: containers
    annotations:
      description: The certificate for {{`{{ $labels.subject_CN }}`}} expires in {{`{{ $value | humanizeDuration }}`}}. See secret {{`{{ $labels.secret_namespace }}`}}/{{`{{ $labels.secret_name }}`}}, key {{`{{ $labels.secret_key }}`}}.
      summary: Certificate expires
