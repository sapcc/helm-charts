# Shoot RBAC parity

Rendered with:

```bash
helm template boot-operator-remote system/boot-operator-remote-ddo \
  --namespace kube-system \
  --set mode=shoot \
  --set boot-operator-core.crd.enable=true \
  --set boot-operator-core.rbac.enable=true \
  --set boot-operator-core.metrics.enable=true \
  --set boot-operator-core.controllerManager.enable=false
```

`--namespace kube-system` mirrors the `DualDeploymentOperator.spec.shootNamespace`
used for this operand. The upstream templates use `.Release.Namespace` for the
ServiceAccount, the namespaced leader-election RBAC, and all RBAC binding
subjects. `values.yaml` sets
`boot-operator-core.controllerManager.serviceAccountName` to
`boot-operator-controller-manager`.

## Inventory diff

The legacy baseline (`system/boot-operator-remote/managedresources/crds-and-rbac.yaml`)
and this render have the same controller ServiceAccount and these equivalent
cluster-scoped grants:

| Resource | Names |
| --- | --- |
| ServiceAccount | `boot-operator-controller-manager` in `kube-system` |
| ClusterRole | `boot-operator-manager-role`, `boot-operator-metrics-auth-role`, `boot-operator-metrics-reader`, `proxy-role`, `httpbootconfig-{editor,viewer}-role`, `ipxebootconfig-{editor,viewer}-role` |
| ClusterRoleBinding | `boot-operator-manager-rolebinding`, `boot-operator-metrics-auth-rolebinding`, `proxy-rolebinding`; every subject is `boot-operator-controller-manager` in `kube-system` |
| CRD | `httpbootconfigs.boot.ironcore.dev`, `ipxebootconfigs.boot.ironcore.dev` |

The legacy manifest contains `boot-operator-metrics-reader` twice with the same
rules; the upstream render does likewise. This does not create an additional
grant.

## Accepted deviation

The legacy manifest models leader election as a `ClusterRole` plus
`ClusterRoleBinding` named `boot-operator-leader-election-{role,rolebinding}`.
The upstream chart now renders an equivalent namespaced `Role` plus `RoleBinding`
in `kube-system`, with the same rules and subject. This is intentional and
accepted: leader-election leases are namespaced, so cluster-scoped permissions
are not required.

No supplemental `shoot-rbac-additions.yaml` is needed: no controller grant is
missing after rendering the upstream chart in the shoot namespace.

## Accepted inert metrics Service duplication

With both `rbac.enable=true` and `metrics.enable=true`, the upstream subchart
emits two differently specified Services named
`boot-operator-controller-manager-metrics-service`: one from
`metrics/metrics-service.yaml` (`targetPort: 8443`) and one from
`rbac/auth_proxy_service.yaml` (`targetPort: https`). Their guards are
independent: the former is gated only by `metrics.enable`, while the latter is
gated only by `rbac.enable`. Both toggles are required to preserve the legacy
metrics-auth ClusterRole and ClusterRoleBinding, so this chart cannot disable
one Service without losing RBAC parity.

This is accepted as an inert upstream-chart quirk in shoot mode. Both Services
select only `control-plane: controller-manager`, while this chart's shoot render
always sets `boot-operator-core.controllerManager.enable=false`; consequently,
neither Service can have a matching controller pod or routable endpoint. The
legacy manifest has analogous harmless duplicate upstream output for the
identical `boot-operator-metrics-reader` ClusterRole. A future DDO CR-level
`transformations: prune` is the appropriate structural cleanup, but is not a
blocker for this chart-only task.

The following shoot render confirms the duplicate selectors and disabled
controller:

```bash
helm template boot-operator-remote system/boot-operator-remote-ddo \
  --namespace kube-system --set mode=shoot \
  --set boot-operator-core.crd.enable=true \
  --set boot-operator-core.rbac.enable=true \
  --set boot-operator-core.metrics.enable=true \
  --set boot-operator-core.controllerManager.enable=false
```

```yaml
# Source: .../templates/metrics/metrics-service.yaml
kind: Service
metadata:
  name: boot-operator-controller-manager-metrics-service
spec:
  ports:
    - targetPort: 8443
  selector:
    control-plane: controller-manager
---
# Source: .../templates/rbac/auth_proxy_service.yaml
kind: Service
metadata:
  name: boot-operator-controller-manager-metrics-service
spec:
  ports:
    - targetPort: https
  selector:
    control-plane: controller-manager
```
