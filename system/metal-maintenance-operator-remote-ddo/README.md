# metal-maintenance-operator-remote-ddo

> **Role: OPERAND chart.** This chart is rendered twice by the
> `dual-deployment-operator` (`mode=seed` / `mode=shoot`) and contains no
> `DualDeploymentOperator` CR. The controller chart owns the CR that directs the
> operator to render this chart.

## Subchart vendoring model

This chart declares the upstream `metal-maintenance-operator` chart as an OCI
dependency in `Chart.yaml` and commits only `Chart.lock` — **not**
`charts/*.tgz`.

```
Chart.yaml     ← declares the metal-maintenance-operator OCI dependency
Chart.lock     ← committed — locks the digest
charts/*.tgz   ← gitignored — NOT committed
```

The publish workflow runs `helm dependency update`, packages the chart, and
pushes the complete artifact. The operator pulls that complete artifact and does
not resolve dependencies at apply time.

## MMO-specific scope

This chart includes no webhook, no cert-manager integration, and owns **two
namespaces** (`metal-maintenance-operator-system` and
`metal-maintenance-sanitization`, both shoot-only additions).

Per-mode subchart enablement comes exclusively from the
`DualDeploymentOperator` CR's `seedValues` and `shootValues`; the chart must
never set a default for `mode`.

The seed additions consist of a single token-requestor Secret
(`remote-kubeconfig.yaml`), which enables the DDO to mint a shoot-side
kubeconfig. No webhook is present.

The shoot additions include:
- Two `Namespace` objects (`metal-maintenance-operator-system`,
  `metal-maintenance-sanitization`)
- OIDC-IAS RBAC: a `metal-maintenance-token-rotate` ServiceAccount + ClusterRole
  + ClusterRoleBinding + namespaced Role + RoleBinding (kube-system), and
  three ClusterRoles/ClusterRoleBindings for cross-operator visibility and
  ServerMaintenance editing
- All shoot-additions objects carry the
  `dual-deployment-operator.cc.sap/origin: additions` annotation

The upstream subchart renders all RBAC as namespaced `Role`/`RoleBinding`
(MMO's `rbac.namespaced=true`). The additions ClusterRoles and ClusterRoleBindings
are therefore entirely SAP-authored; they are not present in the upstream chart
at all.

### Telemetry Service and selector parity

The upstream subchart emits a seed-side Service
`metal-maintenance-operator-controller-manager-telemetry-events` whose selector
is `app.kubernetes.io/name: mmo-core` + `control-plane: controller-manager`.
That selector exactly matches the upstream Deployment's `spec.selector.matchLabels`.
The `ci/selector-parity.sh` gate verifies this on every CI run (see below).

## Shoot RBAC parity

The shoot render enables `mmo-core.rbac.namespaced=true` + `mmo-core.rbac.helpers.enable=true`
plus `mmo-core.serviceAccount.enable=true`. All upstream-originated RBAC is
namespaced (Roles + RoleBindings in `kube-system`). No `ClusterRole` or
`ClusterRoleBinding` comes from the upstream subchart; the additions overlay
supplies all cluster-scoped grants.

The `DualDeploymentOperator` `shootNamespace` must be `kube-system`; the
upstream ServiceAccount and all RBAC binding subjects render into that release
namespace.

The seed additions select the upstream Deployment labels directly:
`app.kubernetes.io/name: mmo-core` and `control-plane: controller-manager`.
They intentionally do not use this wrapper chart's selector labels.

See `examples/rbac-parity.md` for the full shoot-render inventory and accepted
deviations from the legacy manifest.

## CI gates

### `ci/no-mode-default.sh`

Verifies that:
1. `values.yaml` does not declare a default for `mode`
2. `helm template` succeeds (no syntax errors)
3. No additions-origin objects appear in the no-mode render (guards against
   miswritten `{{ if .Values.mode }}` leaks)

### `ci/selector-parity.sh`

**Applicable for MMO.** The upstream subchart emits a telemetry Service whose
selector is expected to match the Deployment's `matchLabels`. Mismatches would
mean the telemetry pipeline is silently broken. This script renders with
`--set mode=seed --set mmo-core.manager.enabled=true`, extracts both selectors
via `yq -o=json`, sorts them with `jq -S`, and `diff`s them; it fails on
mismatch or empty output.

Run either gate from the chart root:

```bash
bash ci/no-mode-default.sh
bash ci/selector-parity.sh
```
