# IPAM DDO overlay reorganization — design

**Date:** 2026-11-02
**Branch:** `feat/ipam-capi-remote-ddo-m-qa-de-200` (lands on draft PR #13218)
**Overlay:** `system/kustomize/ipam-capi-remote-ddo/`
**Size:** small-to-medium change (no new behavior; RBAC trimming + file reorganization + test updates)

## Intent / why

The repair commit (`463740c01f`) restored the migration-inventory objects that
hand-authoring had dropped, but it did so in a way the user flagged for rework:

- It bundled unrelated objects into vague `legacy-support.yaml` files.
- It left the webhook-injector **seed** `ClusterRoleBinding` subject without a
  namespace and papered over it with a fragile per-placement CR `jsonPatch`
  (the "mistake" the user named).
- It carried a leader-election `ClusterRole` promotion that only ever existed as
  a Gardener-resource-manager (GRM) workaround.

Goal: add those objects **properly**, drop the word "legacy", and give the
overlay a cleaner organization — while keeping the overlay **generic**
(reusable across seed namespaces, not pinned to `shoot--cp--m-qa-de-200`).

## Goals

- Make the webhook-injector seed RBAC correct and generic with zero hardcoded
  namespace and zero CR patch.
- Remove RBAC that is dead or redundant for this deployment.
- Replace `legacy-support.yaml` bundles with purpose-named files; drop "legacy"
  naming throughout (code, tests, docs).
- Keep the migration-fidelity tests honest: assert the intentional removals
  rather than the old inventory.

## Non-goals

- No change to the controller image, conversion-webhook wiring, or the
  shoot-side injector ClusterRole (those are correct after `463740c01f`).
- No change to the CRD *bytes* or sha pins in this reorg. The CRD **sourcing
  model** is recorded below (CRD sourcing) but the flip to all-remote is
  deferred to the DDO krusty-fetch work, not done here.
- No live cutover, no activation. The overlay PR stays draft behind its
  platform gates (DDO remote-fetch, admin-chart `source.kustomize` support).

## Anti-goals

- Do **not** reintroduce a per-placement namespace patch or hardcode a seed
  namespace — either defeats "generic".
- Do **not** silently diverge from the chart inventory: every removal is a
  documented, justified deviation.

## Constraints

- DDO renders the seed with `cr.Namespace` and stamps `metadata.namespace` on
  namespaced objects, but **never** touches `subjects[].namespace`
  (`manifest/namespace.go`). Cluster-scoped objects are skipped entirely.
- DDO transformations cannot inject a namespace generically; the only generic
  mechanism for a ClusterRoleBinding subject namespace is a per-placement CR
  patch (rejected).
- `kustomize` v5.8.1; integration branch `master`; run overlay tests from
  `system/kustomize/ipam-capi-remote-ddo/`.

## Approaches considered (webhook-injector seed RBAC)

- **A — drop the dead seed ClusterRole + ClusterRoleBinding; keep the
  namespaced Role + RoleBinding (CHOSEN).** A namespaced RoleBinding with a
  same-namespace ServiceAccount subject needs no explicit subject namespace;
  Kubernetes defaults it to the binding's namespace, which DDO stamps to
  `cr.Namespace`. Generic, zero hardcode, zero CR patch, and it matches the live
  `metal-operator-remote-ddo` overlay. Justified because, with the injector's r7
  args (`--target-kubeconfig` + `--target-label`, no `--managed-resource-label`,
  no `--webhook-config-name`), all CRD/webhook-config patching runs against the
  **shoot** via the target kubeconfig (authorized by the shoot token). The seed
  pod ServiceAccount needs only namespaced perms: its cert Secret and its own
  leader-election Lease. The `resources.gardener.cloud/managedresources`
  ClusterRole is a dead leftover for a mode this deployment never runs.
- **B — keep the ClusterRoleBinding, fill the subject namespace via a
  per-placement CR jsonPatch** (the repaired state). Rejected: fragile,
  per-placement, the exact pattern the user asked to remove.
- **C — keep the ClusterRoleBinding, hardcode the subject namespace.**
  Rejected: not generic.

## Approaches considered (shoot leader-election RBAC)

- **Drop both redundant pairs (CHOSEN).** Two pairs grant identical
  configmap/Lease/event rules to the same subject
  (`ipam-capi-controller-manager@kube-system`):
  `ipam-capi-leader-election-role` (+ binding) and
  `ipam-capi-remote-leader-election-role` (+ binding). Neither is needed: the
  IPAM manager runs `--leader-elect=false`, upstream v1.1.1 defaults it off,
  controller-runtime creates no lock when disabled, and the seed ConfigMap's
  `leaderElect: true` is vestigial (not mounted, not loaded). The `ClusterRole`
  form was only a GRM workaround for GRM's ~3-namespace shoot limit; DDO (which
  SSA-applies the shoot render directly) removes that limit.
- **Demote to one namespaced Role + RoleBinding in `kube-system`.** Kept as a
  belt-and-suspenders fallback if a reviewer wants headroom for a future
  `--leader-elect=true`; not the default. Leases are namespaced, so a
  ClusterRole is never required.

The injector's **own** election RBAC (the seed namespaced Role/RoleBinding from
Approach A) is separate and stays — the injector sidecar runs its own election
with its lease in the seed namespace.

## The decided change set

1. **Webhook-injector seed RBAC** — delete the seed `ClusterRole` +
   `ClusterRoleBinding` `ipam-capi-remote-webhook-injector`; keep the
   `ServiceAccount` + `Role` + `RoleBinding`.
2. **Shoot leader-election RBAC** — delete both
   `ipam-capi-leader-election-role` / `-rolebinding` (from
   `shoot/legacy-support.yaml`) and `ipam-capi-remote-leader-election-role` /
   `-rolebinding` (from `shoot/rbac.yaml`).
3. **Reorganize / de-"legacy"** —
   - `additions/seed/legacy-support.yaml` → `additions/seed/networkpolicies.yaml`
     (3 NetworkPolicies) + `additions/seed/manager-config.yaml`
     (ConfigMap `ipam-capi-manager-config`).
   - `shoot/legacy-support.yaml` → `shoot/metrics-service.yaml`
     (Service `ipam-capi-controller-manager-metrics-service`), with the
     leader-election pair removed per item 2.
   - `tests/legacy_render.py` → `tests/migration_render.py` (update all
     references in `tests/migration_contract.py`, test scripts, README).
   - Use "migration inventory", not "legacy", in comments and docs.
   - Update every affected `kustomization.yaml` `resources:` list.
   - Remove any stray `metadata.namespace` on cluster-scoped objects (the
     deleted leader-election objects carried it; verify none remain elsewhere).
4. **Tests** — update `tests/migration_contract.py` and
   `tests/rbac_fidelity_test.sh` to assert the intentional removals (both
   leader-election pairs + the dead injector seed ClusterRole/binding) and the
   renamed/split files. Record these as deliberate deviations from pure
   chart-inventory fidelity, justified above.
5. **kube-secrets CR #5683** — **no change needed.** Verified: the per-cluster
   instance `dualDeploymentOperatorCRs.ipam-capi-remote` has no seed-namespace
   jsonPatch (its transformations are the two webhook-injector-label patches,
   the kubeconfig ConfigMap patch, and the Deployment host-env patch). The
   fragile patch was only ever *documented* in the README, never added to the
   CR. The README `seed-namespace-contract` section is removed as part of item 3.

## CRD sourcing (target vs today)

The CRDs should be fetched **remotely** (SHA-pinned), not hand-vendored — the
user's direction. The overlay already does this for the 4 provider **pool**
CRDs via a SHA-pinned git directory base
(`cluster-api-ipam-provider-in-cluster//config/crd?ref=7933583…`, v1.1.1).

- **Target model:** all 7 CRDs fetched remotely, SHA-pinned. This becomes
  possible once the DDO **krusty-fetch** capability lands (the user is
  implementing it; it is the remote-base support tracked as DDO issue #58).
- **Today (buildable, DDO-safe):** a hybrid — pool CRDs remote git base (as
  above); the 3 core CAPI CRDs (`clusters.cluster.x-k8s.io`,
  `ipaddresses` / `ipaddressclaims.ipam.cluster.x-k8s.io`) stay **vendored**
  under `shoot/core-crds/` with sha256 pins + a `conversion: {strategy: None}`
  patch.
- **Why the 3 core CRDs can't go remote yet (verified at CAPI
  `5f7d58c9…` = v1.14.2):** `core/config/crd/bases` bundles **13** CRDs and
  there is no CAPI directory containing only our 3. A DDO git-directory base
  would pull 10 unwanted CRDs, and DDO's resolver cannot fetch single raw-HTTP
  files. So remote-all-7 waits on krusty-fetch; until then the 3 stay vendored.

This reorg keeps the hybrid as-is (no CRD byte/pin change). The flip of the 3
core CRDs to a remote base is a follow-up gated on krusty-fetch shipping.

## What's left to the builder

- Confirm DDO prunes resources dropped from a render (stale already-applied
  ClusterRoles/bindings cleanup) so the removals take effect on-cluster; note
  the finding in the plan.
- When trimming the kept seed injector `Role`, decide whether to tighten the
  secret rule to `resourceNames: [ipam-capi-remote-cert-secret]` and whether to
  trim `configmaps`/`events` verbs versus metal's superset — keep metal parity
  unless there's a concrete reason to narrow.
- Mechanical: ordering of `resources:` entries, comment wording.

## Verification

- `kustomize build seed/` and `shoot/` render clean.
- All overlay tests pass from `system/kustomize/ipam-capi-remote-ddo/`,
  including the updated `migration_contract` and `rbac_fidelity` assertions.
- Seed render: injector SA/Role/RoleBinding present, no injector
  ClusterRole/ClusterRoleBinding, no leader-election objects.
- Shoot render: no leader-election RBAC; metrics Service present; shoot injector
  ClusterRole unchanged.
