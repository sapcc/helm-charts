# boot-operator-remote-ddo

> **Role: OPERAND chart.** This chart is rendered twice by the
> `dual-deployment-operator` (`mode=seed` / `mode=shoot`) and contains no
> `DualDeploymentOperator` CR. The controller chart owns the CR that directs the
> operator to render this chart.

## Subchart vendoring model

This chart declares the upstream `boot-operator` chart as an OCI dependency in
`Chart.yaml` and commits only `Chart.lock` — **not** `charts/*.tgz`.

```
Chart.yaml     ← declares the boot-operator OCI dependency
Chart.lock     ← committed — locks the digest
charts/*.tgz   ← gitignored — NOT committed
```

The publish workflow runs `helm dependency update`, packages the chart, and
pushes the complete artifact. The operator pulls that complete artifact and does
not resolve dependencies at apply time.

## Boot-specific scope

This chart includes no webhook, no macdb, no DNS resources, and owns no
namespace. Per-mode subchart enablement comes exclusively from the
`DualDeploymentOperator` CR's `seedValues` and `shootValues`; the chart must
never set a default for `mode`.

## Shoot RBAC parity

The shoot render uses the upstream chart's namespaced `Role` and `RoleBinding`
for leader election rather than the legacy cluster-scoped
`ClusterRole`/`ClusterRoleBinding`. This is an intentional accepted deviation:
leader-election leases are namespaced, so the namespaced grant is sufficient.
The DualDeploymentOperator `shootNamespace` must be `kube-system`; the upstream
ServiceAccount and all RBAC binding subjects render into that release namespace.

The seed additions select the upstream Deployment labels directly:
`app.kubernetes.io/name: boot-operator-core`,
`app.kubernetes.io/instance: boot-operator-remote`, and
`control-plane: controller-manager`. They intentionally do not use this
wrapper chart's selector labels.
