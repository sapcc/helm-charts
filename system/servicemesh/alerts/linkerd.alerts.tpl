groups:
- name: servicemesh.alerts
  rules:
  - alert: LinkerdProxySidecarCertificateExpired
    expr: identity_cert_expiration_timestamp_seconds == 0
    for: 1m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} expired"
      #playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: Linkerd proxy sidecar certificate expired
      description: "Linkerd proxy sidecar certificate in pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} expired. The pod needs to be restarted to get a new certificate."
  - alert: LinkerdTrustAnchorCertificateExpiration
    expr: (secrets_exporter_certificate_not_after{secret="linkerd/linkerd-identity-issuer"} - time()) / 60 / 60 / 24 <= 21
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "Linkerd trust anchor certificate `linkerd/linkerd-identity-issuer` is expiring in less than 21 days."
      #playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "Linkerd trust anchor certificate renewal pending."
      description: "Linkerd trust anchor certificate `linkerd/linkerd-identity-issuer` is expiring in less than 21 days. Please check `certificate` resource in `linkerd` namespace, this might be an issue with cert-manager."
