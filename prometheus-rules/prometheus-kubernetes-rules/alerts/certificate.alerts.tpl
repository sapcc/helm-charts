groups:
- name: certificate.alerts
  rules:
  # Per default cert-manager renews at 33% remaining lifetime
  # https://cert-manager.io/docs/usage/certificate/#reissuance-triggered-by-expiry-renewal
  - alert: X509CertificateLifetimeUnder20Percent
    # basically we are calculating:
    # remaining/lifetime < 0.2
    # to be able to get a proper duration from $value we have to reorder to:
    # remaining < 0.2 * lifetime
    # this means both sides need to join the support group
    # also we clamp to 30 days, to get notified months in advance for long-lived certs
    expr: (x509_cert_not_after - time()) * on(secret_name, secret_namespace) group_left(label_ccloud_support_group) label_replace(label_replace(kube_secret_labels, "secret_name", "$1", "secret", "(.*)"), "secret_namespace", "$1", "namespace", "(.*)") < clamp_max(0.2 * (x509_cert_not_after - x509_cert_not_before) * on(secret_name, secret_namespace) group_left(label_ccloud_support_group) label_replace(label_replace(kube_secret_labels, "secret_name", "$1", "secret", "(.*)"), "secret_namespace", "$1", "namespace", "(.*)"), 30*60*60*24)
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      context: availability
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      support_group: {{ include "supportGroupFromLabelsOrDefault" .Values.supportGroup }}
      playbook: "docs/support/playbook/kubernetes/certificate_expires"
    annotations:
      description: The certificate for {{`{{ $labels.subject_CN }}`}} expires in {{`{{ $value | humanizeDuration }}`}}. See secret {{`{{ $labels.secret_namespace }}`}}/{{`{{ $labels.secret_name }}`}}, key {{`{{ $labels.secret_key }}`}}.
      summary: Certificate expires
