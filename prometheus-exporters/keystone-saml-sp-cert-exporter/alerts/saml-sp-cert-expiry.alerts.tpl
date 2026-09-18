groups:
- name: saml-sp-cert-expiry.alerts
  rules:
  - alert: KeystoneSAMLSPCertExpiryCritical
    expr: (saml_sp_cert_expiry_timestamp - time()) / 86400 <= 90
    for: 1h
    labels:
      tier: os
      service: keystone
      severity: critical
      support_group: identity
      context: saml-sp-cert-expiry
      playbook: /docs/support/identity/saml-sp-cert-rotation
    annotations:
      description: "SAML SP signing cert for tenant={{`{{ $labels.tenant }}`}} region={{`{{ $labels.region }}`}} expires in {{`{{ $value | printf \"%.0f\" }}`}} days. Immediate rotation required."
      summary: "SAML SP cert — immediate rotation required ({{`{{ $labels.tenant }}`}}/{{`{{ $labels.region }}`}})"

  - alert: KeystoneSAMLSPCertExpiryWarning
    expr: (saml_sp_cert_expiry_timestamp - time()) / 86400 <= 180
    for: 1h
    labels:
      tier: os
      service: keystone
      severity: warning
      support_group: identity
      context: saml-sp-cert-expiry
      playbook: /docs/support/identity/saml-sp-cert-rotation
    annotations:
      description: "SAML SP signing cert for tenant={{`{{ $labels.tenant }}`}} region={{`{{ $labels.region }}`}} expires in {{`{{ $value | printf \"%.0f\" }}`}} days. Rotation recommended."
      summary: "SAML SP cert — rotation recommended ({{`{{ $labels.tenant }}`}}/{{`{{ $labels.region }}`}})"
