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
    expr: (x509_cert_not_after{secret_namespace="linkerd",secret_name="linkerd-identity-issuer"} - time()) / 60 / 60 / 24 <= 21
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "Linkerd trust anchor certificate {{`{{ $labels.secret_namespace }}`}}/{{`{{ $labels.secret_name }}`}} is expiring in less than 21 days."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "Linkerd trust anchor certificate renewal pending."
      description: "Linkerd trust anchor certificate in secret {{`{{ $labels.secret }}`}} is expiring in less than 21 days. Please check certificate resource in linkerd namespace, this might be an issue with cert-manager."
  - alert: LinkerdDestinationServicePodsDown
    expr: count(sum by (pod) (up{job="linkerd/linkerd-controller", pod=~"linkerd-destination.*"} == 0)) > 1
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "More than one pod of linkerd destination service is down for 5m. This could break meshing and lead to outages when destination service is not reachable. Investigate linkerd namespace why pods are not running."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "More than one pod of linkerd destination service is down."
      description: "More than one pod of linkerd destination service is down for 5m. This could break meshing and lead to outages when destination service is not reachable. Investigate linkerd namespace why pods are not running."
  - alert: LinkerdIdentityServicePodsDown
    expr: count(sum by (pod) (up{job="linkerd/linkerd-controller", pod=~"linkerd-identity.*"} == 0)) > 1
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "More than one pod of linkerd identity service is down for 5m. This could break meshing and lead to outages when identity service is not reachable. Investigate linkerd namespace why pods are not running."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "More than one pod of linkerd identity service is down."
      description: "More than one pod of linkerd identity service is down for 5m. This could break meshing and lead to outages when identity service is not reachable. Investigate linkerd namespace why pods are not running."
  - alert: LinkerdProxyInjectorPodsDown
    expr: count(sum by (pod) (up{job="linkerd/linkerd-controller", pod=~"linkerd-proxy-injector.*"} == 0)) > 1
    for: 5m
    labels:
      tier: k8s
      service: linkerd
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: servicemesh
      meta: "More than one pod of linkerd proxy injector is down for 5m. This could break meshing when the proxy injector is not running. Investigate linkerd namespace why pods are not running."
      playbook: 'docs/support/playbook/kubernetes/linkerd'
      no_alert_on_absence: "true"
    annotations:
      summary: "More than one pod of linkerd proxy injector is down."
      description: "More than one pod of linkerd proxy injector is down for 5m. This could break meshing when the proxy injector is not running. Investigate linkerd namespace why pods are not running."
