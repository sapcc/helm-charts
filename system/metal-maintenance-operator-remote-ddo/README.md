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
kubeconfig. This Secret does not select any Deployment labels. No webhook is
present.

The shoot additions include:
- Two `Namespace` objects (`metal-maintenance-operator-system`,
  `metal-maintenance-sanitization`)
- OIDC-IAS RBAC: a `metal-maintenance-token-rotate` ServiceAccount + ClusterRole
  + ClusterRoleBinding + namespaced Role + RoleBinding (kube-system), and
  three ClusterRoles/ClusterRoleBindings for cross-operator visibility and
  ServerMaintenance editing
- All shoot-additions objects carry the
  `dual-deployment-operator.cc.sap/origin: additions` annotation

The shoot render uses `mmo-core.rbac.namespaced=false` (cluster-scoped manager
RBAC) and `mmo-core.rbac.helpers.enable=true` (per-CRD admin/editor/viewer
ClusterRoles). The upstream subchart emits cluster-scoped `ClusterRole` and
`ClusterRoleBinding` objects for the manager and the helper set. Leader election
is the only namespaced grant (a `Role` and `RoleBinding` in `kube-system`).

The additions templates supply the OIDC-IAS bindings and the bare
cross-operator grants (see §Carried additions in `examples/rbac-parity.md`).

### Telemetry Service and selector parity

The upstream subchart emits a seed-side Service
`metal-maintenance-operator-controller-manager-telemetry-events` whose selector
is `app.kubernetes.io/name: mmo-core` + `control-plane: controller-manager`.
That selector exactly matches the upstream Deployment's `spec.selector.matchLabels`.
The `ci/selector-parity.sh` gate verifies this on every CI run (see below).

## Shoot RBAC parity

The shoot render enables `mmo-core.rbac.namespaced=false` + `mmo-core.rbac.helpers.enable=true`
plus `mmo-core.serviceAccount.enable=true`. The upstream subchart emits cluster-scoped
`ClusterRole` and `ClusterRoleBinding` objects (manager-role, manager-rolebinding, and
per-CRD helper roles). Leader election is namespaced: `Role` and `RoleBinding` in `kube-system`.
The additions overlay supplies the OIDC-IAS bindings + token-rotate + bare dual-group editor
role (all with `origin: additions`).

The `DualDeploymentOperator` `shootNamespace` must be `kube-system`; the
upstream ServiceAccount and all RBAC binding subjects render into that release
namespace.

The upstream telemetry Service (emitted unconditionally by the subchart) appears in **both**
renders. The DDO CR (Task 8) must apply `filterKinds: {kinds: [Service], source: upstream}`
to drop upstream-origin Services from both renders. A seed-only additions telemetry Service
(`templates/telemetry-service.yaml`) re-provides the :9092 endpoint on the seed with
`origin: additions`, so it survives the source-scoped filter.

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
into variables via `yq` (checked commands — a yq/jq failure causes the script to
fail, not silently pass), validates each is a non-empty JSON object with at least
one key, then compares the sorted forms.

> **Gate boundary:** Both the Deployment `matchLabels` and the telemetry Service
> `selector` are produced by the **same upstream subchart helper**, so a PASS
> establishes mutual **consistency** only — not correctness against legacy or live
> cluster labels. Live label-correctness (comparing rendered selectors against the
> labels actually running in the cluster) is deferred to **Task 6**. Do not rely
> on this gate as evidence that the labels match what is currently deployed.

Run either gate from the chart root:

```bash
bash ci/no-mode-default.sh
bash ci/selector-parity.sh
```
