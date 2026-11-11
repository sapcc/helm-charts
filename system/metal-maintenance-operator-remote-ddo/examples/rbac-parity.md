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

**Live baseline source:** 62 per-CR ManagedResources (`mr-cr-*` / `mr-crb-*` / etc.)
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

**No genuine gaps in ClusterRoles.** All 36 live-only ClusterRoles are unbound orphans
(no `ClusterRoleBinding` in the live cluster references them); they grant no active permissions.

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

| Name | Render (`--include-crds`) | Live (`mr-crd-*`) | Note |
| --- | --- | --- | --- |
| `servermaintenances.maintenance.metal.ironcore.dev` | ✓ | ✓ | Authoritative |
| `biossettings.system.metal.ironcore.dev` | ✓ | ✗ | Subchart CRD, not in mr-crd-* — DDO CRD delivery path TBD (Task 8) |
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

CRDs reside in the subchart's `crds/` directory. `helm template` does not render
`crds/` content without `--include-crds`. The DDO helm source rendering path and whether
it includes CRDs is confirmed during Task 8 / operator CR authoring. The legacy delivered
CRDs as explicit `mr-crd-*` ManagedResources; the DDO path must produce equivalent delivery.

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

**Binding check:** No `ClusterRoleBinding` in the live cluster binds these truncated-name
roles (confirmed from live-baseline.txt CRB list). They are orphaned objects delivering
no active permissions.

**Conclusion: ACCEPTED.** The DDO render delivers the functionally equivalent (and
canonically named) replacement roles. The truncated names will be GC'd on cutover; no
permission regression.

### D2 — Extended helper ClusterRoles absent from subchart (36 roles, render-only-absent)

**Groups:** `baseboard-bmcsettings` (×3), `baseboard-bmcsettingsset` (×3),
`baseboard-bmcuser` (×3), `baseboard-bmcversion` (×3), `baseboard-bmcversionset` (×3),
`readiness-serverwiring` (×3), `system-biossettings` (×3), `system-biossettingsset` (×3),
`system-biosversion` (×3), `system-biosversionset` (×3), `vendorconsole-console` (×3)
= 33 roles, plus the 3 truncated-name duplicates from D1 = total 36 live-only absent.

**Origin:** The legacy `managedresources/rbac.yaml` hand-crafted these roles for expanded
CRD coverage (baseboard, readiness, system, vendorconsole APIs). The upstream `mmo-core-0.1.0`
subchart's `rbac.helpers.enable=true` only generates roles for three resource types:
`bmcusers`, `consoles`, and `servermaintenances`. The extra 33 were never added to the
upstream subchart templates.

**Binding check:** Verified from live-baseline.txt — **zero ClusterRoleBindings** reference
any of these 33+ extended helper roles. They are completely unbound and grant no active
permissions to any principal in the cluster.

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

**Impact:** Harmless extras on the shoot side. The leader-election Role/RoleBinding are
benign in the shoot namespace — they permit configmap/lease operations, which are idle
in the shoot context (no controller running there). They do not expand any actual privilege.

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

## Telemetry Service split (P2)

The subchart template `templates/extras/controller-manager-telemetry-events.yaml` renders
unconditionally (no `manager.enabled` guard). Therefore:

- **Seed render** (`--set mode=seed --set mmo-core.manager.enabled=true`): emits
  `Service/metal-maintenance-operator-controller-manager-telemetry-events` on port 9092. ✓ expected.
- **Shoot render** (`--set mode=shoot --set mmo-core.manager.enabled=false`): also emits the
  **same Service** on port 9092. This is a shoot-side object that should NOT exist there
  (no controller runs on shoot to serve events).

This proves that the DDO CR (Task 8) **genuinely requires a `filterKinds` transformation**
to drop the `Service` kind from the shoot render, even though the chart has no webhooks.
Without `filterKinds`, the shoot would receive the telemetry Service pointing at a
non-existent pod — a stale endpoint that could confuse monitoring.

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
| ClusterRole | `servermaintenance-editor-role` | CRUD on servermaintenances |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-viewer` | Binds IAS group to viewer role |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-editor` | Binds IAS group to editor role |

---

## CI gate results (2026-11-11)

```
ci/no-mode-default.sh  → PASS: no mode default; no additions leak without mode
ci/selector-parity.sh  → PASS: telemetry Service selector matches the upstream Deployment selector
```
