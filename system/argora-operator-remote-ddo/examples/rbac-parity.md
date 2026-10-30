# Shoot RBAC parity

Render the shoot manifest for comparison with the legacy bundle:

```bash
helm dependency build system/argora-operator-remote-ddo

helm template argora-operator-remote system/argora-operator-remote-ddo \
  --namespace kube-system \
  --set mode=shoot \
  --set argora-operator-core.crd.enable=true \
  --set argora-operator-core.rbac.enable=true \
  --set argora-operator-core.metrics.enable=true \
  --set argora-operator-core.manager.enable=false
```

## Shoot inventory and legacy comparison

The following inventory was rendered in `kube-system` and compared by kind,
name, and (for RBAC) rules with the legacy baseline
`system/argora-operator-remote/managedresources/crds-and-rbac.yaml`.

| Kind | Name | Parity / live-path note |
| --- | --- | --- |
| ServiceAccount | `argora-operator-controller-manager` | Same name and namespace as legacy. |
| CustomResourceDefinition | `clusterimports.argora.cloud.sap` | Same as legacy. |
| CustomResourceDefinition | `ippoolimports.argora.cloud.sap` | Same as legacy. |
| CustomResourceDefinition | `updates.argora.cloud.sap` | Same as legacy. |
| ClusterRole | `argora-operator-manager-role` | Rules exactly match the legacy manager-role grant. |
| ClusterRoleBinding | `argora-operator-manager-rolebinding` | Same role reference; subject is `argora-operator-controller-manager` in `kube-system`, matching legacy. |
| Secret | `argora-operator-secret` | Upstream credentials Secret; filtered from the live shoot path by the DDO CR's `filterKinds: [Secret, Service]`. |
| Service | `argora-operator-controller-manager-metrics-service` | Upstream metrics Service; filtered from the live shoot path by the same `filterKinds`. |

No supplemental shoot RBAC additions are required. The rendered CRD names and
the complete `argora-operator-manager-role.rules` list are identical to the
legacy bundle.

## Metrics setting

The legacy managed-resources values used `metrics.enable=true`. In this version
of the upstream chart, that setting gates only
`controller-manager-metrics-service`: rendering with it disabled removes that
Service and leaves the ServiceAccount, all three CRDs, ClusterRole, and
ClusterRoleBinding unchanged. It does not add RBAC or a ServiceMonitor.

Keep `argora-operator-core.metrics.enable=true` in shoot values for strict
legacy-render parity. This is harmless in the live shoot path because the DDO
CR filters the resulting Service; the upstream credentials Secret is filtered
there as well.

## Seed inventory

Render the seed manifest with:

```bash
helm template argora-operator-remote system/argora-operator-remote-ddo \
  --namespace shoot--cp--m-qa-de-200 \
  --set mode=seed \
  --set argora-operator-core.manager.enable=true
```

| Kind | Name | Confirmation |
| --- | --- | --- |
| Secret | `argora-operator-secret` | Credentials Secret mounted by the controller Deployment. |
| Secret | `argora-operator-remote-kubeconfig` | Remote-kubeconfig Secret is present. |
| Deployment | `argora-operator-controller-manager` | Uses ServiceAccount `default`; selector is `app.kubernetes.io/name=argora-operator-core` and `control-plane=controller-manager`. |

The seed render contains no `ClusterImport`, `IPPoolImport`, or `Update` data
CRs and no CRDs or RBAC objects.

## Deliberate seed omissions

The legacy `a-qa-de-200` Argora overlay and legacy chart templates / managed
resources contain no `NetworkPolicy` or `Ingress` for Argora. The operand chart
therefore intentionally renders neither in seed mode.
