# kubelet-csr-approver

Wrapper around [postfinance/kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver).

Kubelets with `serverTLSBootstrap: true` request their serving certificate through a CSR with
signer `kubernetes.io/kubelet-serving`. The kube-controller-manager signs these CSRs, but nothing
approves them. This chart approves them after checking:

- the requestor is `system:node:<name>`, CN is `system:node:<name>` and O is `system:nodes`
- the usages are server auth (no client auth)
- DNS SANs match `providerRegex`
- IP SANs are inside `providerIpPrefixes`
- the requested lifetime is at most `maxExpirationSeconds`

Until a kubelet's serving CSR is approved, the kubelet has no serving certificate, so `kubectl logs`,
`exec`, `port-forward` and metrics scraping fail for that node.

## Deploy order

1. Deploy this chart to the kluster and check that the approver pods are running.
2. Only then set the annotation `kubernikus.cloud.sap/kubelet-serving-certificates: "true"` on the
   Kluster object. Kubernikus then renders `serverTLSBootstrap: true` into the kubelet config for
   newly bootstrapped nodes.

Reverse the order to roll back: remove the annotation, re-bootstrap the affected nodes, then remove this chart.

## Values

| Key | Default | Description |
|-----|---------|-------------|
| `kubelet-csr-approver.providerRegex` | `""` | Required. Regex the DNS SANs must match. |
| `kubelet-csr-approver.providerIpPrefixes` | `[]` | CIDRs the IP SANs must be in (the node networks). |
| `kubelet-csr-approver.bypassDnsResolution` | `true` | Skip resolving the DNS SANs. |
| `kubelet-csr-approver.maxExpirationSeconds` | `"31536000"` | Maximum certificate lifetime. |
| `kubelet-csr-approver.replicas` | `2` | Replicas (leader election is enabled). |

All other values of the upstream chart can be set under `kubelet-csr-approver:`.
