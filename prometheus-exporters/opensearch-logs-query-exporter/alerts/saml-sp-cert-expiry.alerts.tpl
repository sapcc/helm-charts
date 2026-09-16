groups:
- name: saml-sp-cert-expiry.alerts
  rules:
  - alert: KeystoneSAMLSPCertExpiryCritical
    expr: opensearch_logs_saml_sp_cert_expiry_alert_doc_count > 0
    for: 1h
    labels:
      tier: os
      service: keystone
      severity: critical
      context: saml-sp-cert-expiry
      support_group: identity
      no_alert_on_absence: "true"
      meta: "One or more SAML SP certs are within 90 days of expiry or already expired"
    annotations:
      description: "One or more SAML SP signing certs are within 90 days of expiry or already expired in {{`{{ $labels.region }}`}}. Immediate rotation required."
      summary: "SAML SP cert expiry — immediate rotation required"

  - alert: KeystoneSAMLSPCertExpiryWarning
    expr: opensearch_logs_saml_sp_cert_expiry_warn_doc_count > 0
    for: 1h
    labels:
      tier: os
      service: keystone
      severity: warning
      context: saml-sp-cert-expiry
      support_group: identity
      no_alert_on_absence: "true"
      meta: "One or more SAML SP certs are within 180 days of expiry"
    annotations:
      description: "One or more SAML SP signing certs are within 180 days of expiry in {{`{{ $labels.region }}`}}. Rotation recommended."
      summary: "SAML SP cert expiry — rotation recommended"
