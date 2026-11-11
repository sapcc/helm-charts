# Shoot RBAC parity

Rendered with:

```bash
helm template metal-maintenance-operator-remote system/metal-maintenance-operator-remote-ddo \
  --namespace kube-system \
  --set mode=shoot \
  --set mmo-core.crd.enable=true \
  --set mmo-core.manager.enabled=false \
  --set mmo-core.serviceAccount.enable=true \
  --set mmo-core.rbac.namespaced=false \
  --set mmo-core.rbac.helpers.enable=true
```

`--namespace kube-system` mirrors the `DualDeploymentOperator.spec.shootNamespace`
used for this operand. The upstream templates use `.Release.Namespace` for the
ServiceAccount and all namespaced RBAC subjects. `values.yaml` sets
`mmo-core.fullnameOverride: metal-maintenance-operator`.

**Live baseline source:** 60 ManagedResources (`mr-cr-*` / `mr-crb-*` / etc.)
on seed a-qa-de-200 ns `shoot--cp--m-qa-de-200`, captured 2026-11-11T13:01:00Z.
The authoritative MMO-owned object set is the `mr-*` list, not the broad
`get clusterrole,…` result (which may include other operators / core k8s objects).

---

## Resolved flags

### `mmo-core.rbac.helpers.enable`

**Resolved value: `true`.**

The live cluster's `mr-cr-*` ManagedResources include the full per-CRD
admin/editor/viewer helper-role set (bmcuser, console, servermaintenance × 3 each)
delivered by `mr-cr-metal-maintenance-operator-{bmcuser,console,servermaintenance}-{admin,editor,viewer}-role`.
These match the roles the subchart generates under `rbac.helpers.enable: true`.

**Required CR shootValues:** `mmo-core.rbac.helpers.enable: true` (Task 8 sets this).
**values.yaml change: NOT required.** The `values.yaml` correctly defaults all subchart
flags to `false` to keep the chart mode-agnostic. The CR's `spec.source.helm.shootValues`
injects this flag at render time, just as for all other per-mode subchart flags. Setting
a default in `values.yaml` would break the mode-agnostic contract.

---

## Inventory diff

Live = `mr-*` ManagedResources authoritative set. Render = `helm template … --set mode=shoot`.

### ServiceAccounts

| Name | Namespace | Render | Live (`mr-sa-*`) | Classification |
| --- | --- | --- | --- | --- |
| `metal-maintenance-operator-controller-manager` | kube-system | ✓ | ✓ | **Match** |
| `metal-maintenance-token-rotate` | kube-system | ✓ | ✓ | **Match** (carried addition) |

### ClusterRoles

| Name | Render | Live (`mr-cr-*`) | Classification |
| --- | --- | --- | --- |
| `metal-maintenance-operator-manager-role` | ✓ | ✓ | **Match** |
| `metal-maintenance-operator-bmcuser-admin-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-bmcuser-editor-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-bmcuser-viewer-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-console-admin-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-console-editor-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-console-viewer-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-servermaintenance-admin-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-servermaintenance-editor-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-servermaintenance-viewer-role` | ✓ | ✓ | **Match** (helpers) |
| `metal-maintenance-operator-viewer` | ✓ | ✓ | **Match** (carried addition, Task 4) |
| `metal-maintenance-token-rotate` | ✓ | ✓ | **Match** (carried addition, Task 4) |
| `servermaintenance-editor-role` | ✓ | ✓ | **Match** (carried addition, Task 4) |
| `metal-maintenance-oper-maintenance-servermaintenance-admin-role` | ✗ | ✓ | **Accepted deviation — orphaned role** (see §Accepted deviations D1) |
| `metal-maintenance-ope-maintenance-servermaintenance-editor-role` | ✗ | ✓ | **Accepted deviation — orphaned role** (see §Accepted deviations D1) |
| `metal-maintenance-ope-maintenance-servermaintenance-viewer-role` | ✗ | ✓ | **Accepted deviation — orphaned role** (see §Accepted deviations D1) |
| `metal-maintenance-operator-baseboard-bmcsettings-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-baseboard-bmcsettingsset-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-baseboard-bmcuser-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-baseboard-bmcversion-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-baseboard-bmcversionset-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-readiness-serverwiring-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-system-biossettings-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-system-biossettingsset-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-system-biosversion-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-system-biosversionset-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |
| `metal-maintenance-operator-vendorconsole-console-{admin,editor,viewer}-role` (×3) | ✗ | ✓ | **Accepted deviation — orphaned roles** (see §Accepted deviations D2) |

**No genuine gaps in ClusterRoles.** All 36 live-only ClusterRoles are verified unbound
and unaggregated orphans — proved by three independent axes from live capture
(2026-11-11T13:10:12Z, evidence file `task-6-live-roleref-evidence.txt`):
(1) **Exhaustive CRB roleRef check:** all 8 MMO-relevant CRBs resolved to their actual
`roleRef.name`; none reference any of the 36.
(2) **Exhaustive RoleBinding roleRef check:** only `kube-system/metal-maintenance-token-rotate`
targets an MMO Role (in render); no RoleBinding references any of the 36.
(3) **Complete aggregator enumeration (inverted check):** across all 207 live ClusterRoles,
the ONLY 3 carrying an `aggregationRule` are `admin`, `edit`, and `view` (the standard k8s
roles). Their `clusterRoleSelectors` reference exclusively the 3 standard keys
`rbac.authorization.k8s.io/aggregate-to-{admin,edit,view}` — there are no `matchExpressions`
and no custom label keys. None of the 36 orphan roles carry any of those keys. Therefore no
aggregationRule, standard or custom, selects any of the 36, closing the transitive path
completely. See §Accepted deviations D1/D2.

### ClusterRoleBindings

| Name | Render | Live (`mr-crb-*`) | Classification |
| --- | --- | --- | --- |
| `metal-maintenance-operator-manager-rolebinding` | ✓ | ✓ | **Match** |
| `metal-maintenance-token-rotate` | ✓ | ✓ | **Match** (carried addition) |
| `cc:oidc-ias-maintenance-viewer` | ✓ | ✓ | **Match** (carried addition, Task 4) |
| `cc:oidc-ias-maintenance-editor` | ✓ | ✓ | **Match** (carried addition, Task 4) |

### Roles (namespaced, kube-system)

| Name | Render | Live (`mr-r-*`) | Classification |
| --- | --- | --- | --- |
| `metal-maintenance-token-rotate` | ✓ | ✓ | **Match** (carried addition) |
| `metal-maintenance-operator-leader-election-role` | ✓ | ✗ | **Accepted deviation — render-extra** (see §Accepted deviations D3) |

### RoleBindings (namespaced, kube-system)

| Name | Render | Live (`mr-rb-*`) | Classification |
| --- | --- | --- | --- |
| `metal-maintenance-token-rotate` | ✓ | ✓ | **Match** (carried addition) |
| `metal-maintenance-operator-leader-election-rolebinding` | ✓ | ✗ | **Accepted deviation — render-extra** (see §Accepted deviations D3) |

### CRDs

| Name | Render (`--include-crds --set mmo-core.crd.enable=true`) | Live (`mr-crd-*`) | Note |
| --- | --- | --- | --- |
| `servermaintenances.maintenance.metal.ironcore.dev` | ✓ | ✓ | **Match** — sole live mr-crd-* entry |
| `biossettings.system.metal.ironcore.dev` | ✓ | ✗ | Subchart CRD, templated by 0.1.0-crds (gated by crd.enable) |
| `biossettingssets.system.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `biosversions.system.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `biosversionsets.system.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `bmcsettings.baseboard.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `bmcsettingssets.baseboard.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `bmcusers.baseboard.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `bmcversions.baseboard.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `bmcversionsets.baseboard.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `consoles.vendorconsole.metal.ironcore.dev` | ✓ | ✗ | (same) |
| `serverwirings.readiness.metal.ironcore.dev` | ✓ | ✗ | (same) |

**CRD count reconciliation (R7):** The `0.1.0-crds` subchart variant moves all CRDs
from the static `crds/` directory into `templates/crd/*.yaml`, each gated by
`{{ if .Values.crd.enable }}`. The seed render (`mmo-core.crd.enable=false`) emits
**0 CRDs** even with `--include-crds`. The shoot render (`mmo-core.crd.enable=true`)
emits **12 CRDs** — all 12 files in `templates/crd/`. The old static `crds/crds.yaml`
in 0.1.0 contained 12 CRDs (same set), so the CRD content is identical between versions.

Live baseline has only 1 mr-crd-* entry (`servermaintenances`). The remaining 11 CRDs in
the shoot render are a **superset** — the upstream subchart templates them but the legacy
delivery omitted them from ManagedResources. This is not a permission regression (CRDs are
cluster-scoped, install-time objects). The DDO shoot render delivers the full CRD set the
upstream chart defines. See §CRD delivery note below.

---

## Accepted deviations

### D1 — Truncated-name servermaintenance helper roles (3 roles, render-only-absent)

**Names:**
- `metal-maintenance-oper-maintenance-servermaintenance-admin-role`
- `metal-maintenance-ope-maintenance-servermaintenance-editor-role`
- `metal-maintenance-ope-maintenance-servermaintenance-viewer-role`

**Origin:** These are legacy truncation artifacts. The legacy chart used a different
helm `fullnameOverride` + suffix combination that produced these 63-char-truncated names
(the `resourceName` helper: `metal-maintenance-operator`[22] + `-` + `maintenance-servermaintenance-admin-role`[40] = truncated to 62 chars).
The upstream `mmo-core-0.1.0` subchart now uses the suffix `servermaintenance-*-role`,
producing `metal-maintenance-operator-servermaintenance-{admin,editor,viewer}-role` —
the correct, shorter names. The DDO render delivers the correct canonical names.

**Binding proof (live roleRef capture 2026-11-11T13:10:12Z, evidence file `task-6-live-roleref-evidence.txt`):**
(1) All 8 MMO-relevant CRBs were resolved to their actual `roleRef.name`; none reference
any of these truncated names. (2) The only RoleBinding in kube-system referencing an MMO
role targets `metal-maintenance-token-rotate` (in render). (3) **Complete aggregator
enumeration:** across all 207 live ClusterRoles, the only 3 carrying an `aggregationRule`
are `admin`, `edit`, and `view`. Their `clusterRoleSelectors` reference exclusively the 3
standard keys `rbac.authorization.k8s.io/aggregate-to-{admin,edit,view}` — no
`matchExpressions`, no custom label keys. None of these 3 truncated names carry any of those
keys, so no aggregationRule (standard or custom) selects them. These 3 roles are
definitively unreferenced and unaggregated — they deliver zero effective permissions.

**Conclusion: ACCEPTED.** The DDO render delivers the functionally equivalent (and
canonically named) replacement roles. The truncated names will be GC'd on cutover; no
permission regression.

### D2 — Extended helper ClusterRoles absent from subchart (33 roles, render-only-absent)

**Groups:** `baseboard-bmcsettings` (×3), `baseboard-bmcsettingsset` (×3),
`baseboard-bmcuser` (×3), `baseboard-bmcversion` (×3), `baseboard-bmcversionset` (×3),
`readiness-serverwiring` (×3), `system-biossettings` (×3), `system-biossettingsset` (×3),
`system-biosversion` (×3), `system-biosversionset` (×3), `vendorconsole-console` (×3)
= **33 roles** (D1 + D2 = 36 live-only total).

**Origin:** The legacy `managedresources/rbac.yaml` hand-crafted these roles for expanded
CRD coverage (baseboard, readiness, system, vendorconsole APIs). The upstream `mmo-core-0.1.0`
subchart's `rbac.helpers.enable=true` only generates roles for three resource types:
`bmcusers`, `consoles`, and `servermaintenances`. The extra 33 were never added to the
upstream subchart templates.

**Binding proof (live roleRef capture 2026-11-11T13:10:12Z, evidence file `task-6-live-roleref-evidence.txt`):**
Same three axes as D1: (1) all 8 MMO-relevant CRBs resolved to their actual `roleRef.name`
— none reference any of these 33 extended helper roles; every active MMO grant points at a
role the DDO render reproduces. (2) No RoleBinding references any of these names.
(3) **Complete aggregator enumeration (inverted check):** across all 207 live ClusterRoles,
the ONLY 3 carrying an `aggregationRule` are `admin`, `edit`, and `view`. Their
`clusterRoleSelectors` reference exclusively the 3 standard keys
`rbac.authorization.k8s.io/aggregate-to-{admin,edit,view}` — there are no `matchExpressions`
and no custom label keys anywhere. None of the 33 roles (baseboard-\*/readiness-\*/system-bios\*/vendorconsole-\*)
carry any of those keys. Therefore no aggregationRule, standard or custom, selects any of
the 33. The 33 roles are definitively unreferenced and unaggregated — they deliver zero
effective permissions to any principal.

**Conclusion: ACCEPTED.** No active permission regression on cutover. These orphaned helper
roles will be garbage-collected by GRM when the legacy ManagedResources are deleted. If a
future need arises to bind these roles, the DDO additions template can add them.

### D3 — Leader-election Role + RoleBinding (render-extra, not in live mr-* set)

**Names:** `metal-maintenance-operator-leader-election-role`,
`metal-maintenance-operator-leader-election-rolebinding` (both in kube-system)

**Origin:** The subchart always renders these (no guard flag). The legacy chart did not
include them in its shoot-side ManagedResources (leader election is a seed concern — the
controller runs on the seed, not the shoot). They appear in the DDO shoot render because
the subchart doesn't distinguish seed/shoot for this template.

**Impact:** This is a **render-only permission addition** relative to the live baseline.
The legacy chart did not deliver a leader-election Role to the shoot cluster (confirmed:
`mr-r-*` list contains only `metal-maintenance-token-rotate`; the legacy manager likely
ran with `--leader-elect=false` or obtained the role via seed-side delivery only).

The rendered Role grants to the `metal-maintenance-operator-controller-manager` SA
(in kube-system) — via the accompanying RoleBinding — standard leader-election permissions:
`ConfigMap` get/list/watch/create/update/patch/delete, `coordination.k8s.io/leases` same
CRUD, and `core/events` create/patch, all scoped to the `kube-system` namespace. Because
the seed controller uses the shoot credentials to operate on the shoot cluster, these
permissions **are effective** via the shoot API server.

**Acceptance rationale:** The grant is standard, bounded, and namespace-scoped (kube-system
only). It confers no access to CRs, cluster-wide resources, or data outside kube-system.
If the DDO deployment enables leader election in the controller (which is the upstream
default), this Role is required for correct operation. It represents a minor, intentional
permission expansion over the legacy posture — accepted as a safe, standard pattern
consistent with every other DDO-migrated operator.

**Conclusion: ACCEPTED.** Render-extra, not missing-from-render. No functional regression.

---

## F1: Immutable selector — verified non-issue

The live Deployment `metal-maintenance-operator-controller-manager` on seed a-qa-de-200
(ns `shoot--cp--m-qa-de-200`) has immutable selector:

```json
{"app.kubernetes.io/name":"mmo-core","control-plane":"controller-manager"}
```

The DDO render produces the IDENTICAL selector labels because both the legacy and DDO
charts use the **same subchart alias `mmo-core`**, and the subchart sets
`app.kubernetes.io/name` from its own chart name (the alias), not from `fullnameOverride`.
In-place cutover does NOT trip the immutable-selector hazard.

No `nameOverride` is needed. This was confirmed by running `helm template` against the DDO
chart and comparing the rendered Deployment selector with the live cluster state.

---

## Telemetry Service split (R8 — resolved)

The subchart template `templates/extras/controller-manager-telemetry-events.yaml` renders
unconditionally (no `manager.enabled` guard). Therefore:

- **Seed render** (`--set mode=seed --set mmo-core.manager.enabled=true`): emits
  `Service/metal-maintenance-operator-controller-manager-telemetry-events` on port 9092
  with `origin: upstream`. ✓ expected, but must survive the shoot Service filter.
- **Shoot render** (`--set mode=shoot --set mmo-core.manager.enabled=false`): also emits
  **the same Service** on port 9092 with `origin: upstream`. This must be dropped —
  no controller runs on shoot.

### DDO transform investigation (R8)

The DDO `filterKinds` transformation supports a `source` field (maps to manifest origin):

```go
type FilterKindsSpec struct {
    Kinds  []string `json:"kinds"`
    Source string   `json:"source,omitempty"` // matches manifest.Origin exactly
}
```

`source: upstream` restricts the drop to manifests with `origin == "upstream"` (i.e.,
resources NOT carrying the `dual-deployment-operator.cc.sap/origin: additions` annotation).

**Correct CR transformation (Task 8):**
```yaml
transformations:
  - filterKinds:
      kinds: [Service]
      source: upstream
```

This applies to BOTH renders (transformations are per-render, not mode-scoped):
- **Seed render:** upstream-origin telemetry Service is dropped. The additions-origin
  `templates/telemetry-service.yaml` Service (origin: additions, same name, same selector,
  port 9092) is NOT dropped — it survives the source-scoped filter. ✓ Seed has exactly
  one working :9092 telemetry Service after transform.
- **Shoot render:** upstream-origin telemetry Service is dropped. The additions Service
  is seed-only (`{{- if eq .Values.mode "seed" }}`), so it does not appear in the shoot
  render at all. ✓ Shoot ends up with zero telemetry Services — correct.

**Why not `filterKinds: {kinds: [Service]}`** (no source): drops ALL Services from both
renders including any additions-origin ones — the seed would end up with no telemetry
Service. Rejected.

**Why not a name+jsonPatch deletion:** The `patch` transform selects by kind/name/origin
but cannot "delete an object from the render stream" — it mutates object fields, not
removes objects. `filterKinds` is the correct removal mechanism. With `source: upstream`
it is precise enough.

### Render assertion

After applying `filterKinds: {kinds: [Service], source: upstream}` (Task 8 CR):

| Render | Telemetry Service present | Port | Origin |
| --- | --- | --- | --- |
| Seed | ✓ `metal-maintenance-operator-controller-manager-telemetry-events` | 9092 | additions |
| Shoot | ✗ (none) | — | — |

---

## CRD delivery note

The `0.1.0-crds` subchart variant ships CRDs as `templates/crd/*.yaml` gated by
`{{ if .Values.crd.enable }}`. The DDO CR (Task 8) sets:
- `seedValues: {mmo-core: {crd: {enable: false}}}` → 0 CRDs on seed ✓
- `shootValues: {mmo-core: {crd: {enable: true}}}` → 12 CRDs on shoot

All 12 shoot CRDs are delivered as shoot-side managed resources. Only
`servermaintenances.maintenance.metal.ironcore.dev` was delivered by the legacy chart
(`mr-crd-*`). The remaining 11 are a superset expansion, not a regression.

---

## Carried additions

The shoot render includes the following SAP-authored additions (not present in
the upstream subchart):

| Resource | Name | Purpose |
| --- | --- | --- |
| ServiceAccount | `metal-maintenance-token-rotate` in `kube-system` | Token rotation for cross-operator access |
| ClusterRole | `metal-maintenance-token-rotate` | Allows `tokenreviews` create |
| ClusterRoleBinding | `metal-maintenance-token-rotate` | Binds token-rotate SA |
| Role | `metal-maintenance-token-rotate` in `kube-system` | Allows `serviceaccounts/token` create for controller-manager SA |
| RoleBinding | `metal-maintenance-token-rotate` in `kube-system` | Binds token-rotate SA |
| ClusterRole | `metal-maintenance-operator-viewer` | Read access to serverwirings + consoles |
| ClusterRole | `servermaintenance-editor-role` | CRUD on servermaintenances (GET-only on /status) |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-viewer` | Binds IAS group to viewer role |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-editor` | Binds IAS group to editor role |

The seed render includes the following SAP-authored additions:

| Resource | Name | Purpose |
| --- | --- | --- |
| Secret | `metal-maintenance-operator-kubeconfig` in `kube-system` | Token-requestor seed Secret |
| Service | `metal-maintenance-operator-controller-manager-telemetry-events` | Seed-side telemetry :9092 (additions-origin, survives filterKinds source:upstream) |

---

## CI gate results (2026-11-11, updated after final-fix wave)

```
ci/no-mode-default.sh  → PASS: no mode default; no additions leak without mode
ci/selector-parity.sh  → PASS: telemetry Service selector matches the upstream Deployment selector
```
