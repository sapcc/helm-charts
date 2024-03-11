groups:
- name: servicemesh.alerts
  rules:
  - alert: LinkerdProxySidecarCertificateExpiringSoon
    expr: identity_cert_expiration_timestamp_seconds - time() < 7200
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning # promote to critical after some testing
      context: servicemesh
      meta: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is expiring in less than 2h."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: Linkerd proxy sidecar certificate expiring
      description: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is expiring in less than 2h. Immediate action is required or network connectivity might be lost."
  - alert: LinkerdProxySidecarCertificateExpiring
    expr: identity_cert_expiration_timestamp_seconds - time() < 86400
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is expiring in less than 24h."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: Linkerd proxy sidecar certificate expiring
      description: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is expiring in less than 24h. Immediate action is required or network connectivity might be lost."
  - alert: LinkerdTrustAnchorCertificateExpiration
    expr: (secrets_exporter_certificate_not_after{secret="linkerd/linkerd-identity-issuer"} - time()) / 60 / 60 / 24 <= 21
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "Linkerd trust anchor certificate {{`{{ $labels.secret }}`}} is expiring in less than 21 days."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "Linkerd trust anchor certificate renewal pending."
      description: "Linkerd trust anchor certificate in secret {{`{{ $labels.secret }}`}} is expiring in less than 21 days. Please check certificate resource in linkerd namespace, this might be an issue with cert-manager."
