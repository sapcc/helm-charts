groups:
- name: certificate.alerts
  rules:
  - alert: X509CertificateExpiresIn30Days
    expr: (x509_cert_not_after - time()) * on(secret_name, secret_namespace) group_left(label_ccloud_support_group) label_replace(label_replace(kube_secret_labels, "secret_name", "$1", "secret", "(.*)"), "secret_namespace", "$1", "namespace", "(.*)") <= 30*60*60*24
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      context: availability
      service: certificates
      severity: info
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
    annotations:
      description: The certificate for {{`{{ $labels.subject_CN }}`}} expires in {{`{{ $value | humanizeDuration }}`}}. See secret {{`{{ $labels.secret_namespace }}`}}/{{`{{ $labels.secret_name }}`}}, key {{`{{ $labels.secret_key }}`}}.
      summary: Certificate expires
