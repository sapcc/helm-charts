# argora-operator-remote-ddo

> **Role: OPERAND chart.** This chart is rendered twice by the
> `dual-deployment-operator` (`mode=seed` / `mode=shoot`) and contains no
> `DualDeploymentOperator` CR. The controller chart owns the CR that directs the
> operator to render this chart.

## Subchart vendoring model

This chart declares the upstream `argora` chart as an OCI dependency in
`Chart.yaml` and commits only `Chart.lock` — **not** `charts/*.tgz`.

```
Chart.yaml     ← declares the argora OCI dependency
Chart.lock     ← committed — locks the digest
charts/*.tgz   ← gitignored — NOT committed
```

The publish workflow runs `helm dependency update`, packages the chart, and
pushes the complete artifact. The operator pulls that complete artifact and does
not resolve dependencies at apply time.

## Argora-specific scope

This chart includes no webhook and owns no namespace. Per-mode subchart
enablement comes exclusively from the `DualDeploymentOperator` CR's `seedValues`
and `shootValues`; the chart must never set a default for `mode`.

The seed controller uses the `default` ServiceAccount. Vault credential resolve
directives are carried in `values.yaml`; `secrets-injector` resolves them
in-cluster rather than Helm resolving secrets. `ClusterImport`, `IPPoolImport`,
and `Update` data CRs render as `mode=shoot` additions in `kube-system`.

`argora-operator-core.fullnameOverride: argora-operator` preserves the legacy
bundle's shoot ServiceAccount/RBAC identity and the `token-requestor` identity.

## Shoot RBAC parity

The shoot render has the same ServiceAccount, three CRDs, manager ClusterRole,
and manager ClusterRoleBinding (including all ClusterRole rules) as the legacy
`managedresources/crds-and-rbac.yaml` bundle. Its ClusterRoleBinding subject is
`argora-operator-controller-manager` in `kube-system`.

`argora-operator-core.metrics.enable=true` is retained in `shootValues` for
legacy render parity. It adds only the upstream metrics Service; it adds no RBAC
or ServiceMonitor. The DDO CR filters `Service` and `Secret` kinds from the live
shoot path, so that Service and the upstream credentials Secret are intentionally
not applied there.

See [`examples/rbac-parity.md`](examples/rbac-parity.md) for the exact render
commands, complete inventories, and the rules comparison.
