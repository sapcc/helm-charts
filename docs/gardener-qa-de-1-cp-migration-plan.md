# `mgmt-qa-de-1` CP migration plan (post-#12197)

> **Status:** Ready-to-execute runbook for the one-off control-plane
> migrations to perform on `mgmt-qa-de-1` after
> [`sapcc/helm-charts#12197`](https://github.com/sapcc/helm-charts/pull/12197)
> merges and the `zoneSelection: Prefer` setting is applied to the
> seed.
>
> **Audience:** whoever executes the migration. Read
> [`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
> and [`gardener-qa-de-1-cp-az-findings.md`](./gardener-qa-de-1-cp-az-findings.md)
> first for the "why".
>
> **Snapshot date:** 2026-07-07 (verify with §2.1 before executing).

---

## Table of contents

1. [TL;DR](#1-tldr)
2. [Current live status of `mgmt-qa-de-1`](#2-current-status)
   - [2.1 One-liner to re-check the state](#2-1-recheck)
3. [Per-shoot decision](#3-per-shoot-decision)
4. [Migration recipe (Ceph-safe)](#4-recipe)
5. [Pre-flight checks](#5-preflight)
6. [Full command sequence for `cc-b1-qa-de-1`](#6-cc-b1-commands)
7. [Verification](#7-verification)
8. [Rollback if something goes wrong](#8-rollback)
9. [What we deliberately do NOT touch](#9-out-of-scope)
10. [Open follow-up items](#10-followups)

---

## 1. TL;DR <a id="1-tldr"></a>

- Merging the PR does **not** move anything. `zoneSelection` only
  applies to *new* CP namespace creations. Existing CPs stay where
  they are until an operator acts.
- On `mgmt-qa-de-1` today, exactly **one** CP is a candidate for
  migration: `cc-b1-qa-de-1` (workers in `qa-de-1b`, CP in
  `qa-de-1a`).
- **But** that shoot is stuck in `Create | Failed | 79%`. Do not
  migrate it until the underlying create failure is resolved.
- `cc-b0-qa-de-1` is currently `Reconcile | Failed | 79%` — needs
  investigation, no migration action.
- `cc-d0-qa-de-1` cannot be migrated at all on this seed (workers in
  `qa-de-1d`, seed has no `1d` nodes). Blocked on AZ-D readiness.
- `lh-b-qa-de-1` needs the Lighthouse workaround (separate PR), not
  a one-off migration.

**Net actionable list on `mgmt-qa-de-1`:** zero migrations executable
today. Two shoots (`cc-b0`, `cc-b1`) need diagnosis first; one
(`cc-d0`) is blocked on the seed; one (`lh-b`) needs the separate
workaround.

---

## 2. Current live status of `mgmt-qa-de-1` <a id="2-current-status"></a>

Captured 2026-07-07 09:03 CEST.

```
Seed provider.zones: [qa-de-1a, qa-de-1b]
Seed nodes:          3 × qa-de-1a, 3 × qa-de-1b  (no nodes in 1c or 1d)
```

| Shoot           | lastOperation                | Worker zones | CP annotation | Actual CP AZ | Aligned to workers?              |
| --------------- | ---------------------------- | ------------ | ------------- | ------------ | --------------------------------- |
| `cc-b0-qa-de-1` | Reconcile \| Failed \| 79%    | `qa-de-1b`   | `qa-de-1b`    | `qa-de-1b`   | ✅ yes (by luck)                   |
| `cc-b1-qa-de-1` | Create \| Failed \| 79%       | `qa-de-1b`   | `qa-de-1a`    | `qa-de-1a`   | ❌ no — misplaced                   |
| `cc-d0-qa-de-1` | Reconcile \| Succeeded \| 100% | `qa-de-1d`   | `qa-de-1a`    | `qa-de-1a`   | ⚠ impossible on this seed          |
| `lh-b-qa-de-1`  | Reconcile \| Succeeded \| 100% | *(workerless)* | `qa-de-1b`   | `qa-de-1b`   | ✅ correct by name (see §9)        |

### 2.1 One-liner to re-check the state before executing <a id="2-1-recheck"></a>

State can drift between the time this doc was written and the time
you actually run the migration. Always re-check right before
acting:

```bash
u8s --context mgmt-qa-de-1 kubectl get nodes -o json \
  | python3 -c "
import json, sys, subprocess as sp
nodes = {n['metadata']['name']: n['metadata']['labels'].get('topology.kubernetes.io/zone','?') for n in json.load(sys.stdin)['items']}
gw = json.loads(sp.check_output(['u8s','--context','g-qa-de-1','kubectl','get','shoot','-A','-o','json'], text=True))
seed_zones = json.loads(sp.check_output(['u8s','--context','g-qa-de-1','kubectl','get','seed','mgmt-qa-de-1','-o','jsonpath={.spec.provider.zones}'], text=True))
print(f'seed zones: {seed_zones}')
for s in gw['items']:
    if s.get('spec',{}).get('seedName') != 'mgmt-qa-de-1': continue
    name = s['metadata']['name']
    proj = s['metadata']['namespace'].replace('garden-','') if s['metadata']['namespace'].startswith('garden-') else 'garden'
    ns = f'shoot--{proj}--{name}'
    op = s.get('status',{}).get('lastOperation',{}) or {}
    wz = ','.join(sorted({z for w in (s.get('spec',{}).get('provider',{}).get('workers',[]) or []) for z in w.get('zones',[])})) or '<workerless>'
    ann = sp.check_output(['u8s','--context','mgmt-qa-de-1','kubectl','get','ns',ns,'-o','jsonpath={.metadata.annotations.high-availability-config\\\\.resources\\\\.gardener\\\\.cloud/zones}'], text=True).strip() or '<none>'
    pods = sp.check_output(['u8s','--context','mgmt-qa-de-1','kubectl','get','pods','-n',ns,'-l','role=apiserver','-o','jsonpath={.items[*].spec.nodeName}'], text=True).split()
    pz = ','.join(sorted({nodes.get(p,'?') for p in pods})) if pods else '<none>'
    print(f'{name:18} op={op.get(\"type\",\"?\"):10} {op.get(\"state\",\"?\"):10} {op.get(\"progress\",\"?\"):>4}% workers={wz:22} ann={ann:12} cpaz={pz}')
"
```

If the values in the table above no longer match this output, do
not proceed with the migration commands verbatim — update the plan
first.

---

## 3. Per-shoot decision <a id="3-per-shoot-decision"></a>

### 3.1 `cc-b0-qa-de-1` — wait, do not migrate

- CP already in the right AZ (`qa-de-1b`).
- Shoot is unhealthy (`Reconcile | Failed | 79%`), and the failure
  is unrelated to CP placement (annotation matches workers).
- Investigation needed before any operational action.
- **Action for #943 rollout:** none. Once the reconcile failure is
  resolved by whoever owns it, the shoot naturally stays aligned.

### 3.2 `cc-b1-qa-de-1` — target for migration, but blocked

- CP in `qa-de-1a`, workers in `qa-de-1b`. Live misplacement.
- Would benefit directly from Recipe A → migrate to `qa-de-1b`.
- **But** shoot has been in `Create | Failed | 79%` for 21+ days —
  it never finished initial creation.
- Migrating a shoot that is still in a Create-Failed state is
  dangerous:
  - Etcd may not have completed initial data-plane setup.
  - Backups may be inconsistent / not yet running.
  - Restarting CP pods may either fix or worsen the underlying
    create failure, depending on the root cause.
- **Action for #943 rollout:** deferred. Diagnose the create
  failure first (see §10.1). Once the shoot reaches
  `Succeeded | 100%`, run Recipe A.

### 3.3 `cc-d0-qa-de-1` — impossible on this seed today

- Workers declared in `qa-de-1d`; seed has no `1d` nodes at all.
- No possible target AZ on this seed. Recipe A does not apply.
- Blocked on the AZ-D readiness workstream (Compute + Metal + Seed
  teams re-adding `qa-de-1d` to the seed).
- **Action for #943 rollout:** none. Track under `#943` follow-up.

### 3.4 `lh-b-qa-de-1` — do not touch, wait for Lighthouse workaround

- Workerless, so `zoneSelection` cannot align it algorithmically.
- Currently in `qa-de-1b`, which matches the naming convention
  intent — but by coincidence of Gardener's random pick, not by any
  enforced rule.
- Manually annotating this namespace *would* pin it to `1b`, but
  it's already there; the action would be a no-op with the same
  risk of accidentally flipping the annotation to a wrong value.
- **Action for #943 rollout:** none. Wait for the dedicated
  Lighthouse workaround (mutating webhook — see §10.3) which will
  handle this and all future Lighthouse shoots uniformly.

---

## 4. Migration recipe (Ceph-safe) <a id="4-recipe"></a>

This is the recipe applicable to `cc-b1-qa-de-1` **once its create
failure is resolved**. It relies on `mgmt-qa-de-1`'s Ceph storage,
where volumes are not AZ-bound. Do NOT use this recipe on a seed
with hyperscaler storage.

Given:
- `NS` — the shoot's CP namespace on the seed (e.g. `shoot--compute--cc-b1-qa-de-1`).
- `TARGET_AZ` — the AZ we're moving to (e.g. `qa-de-1b`).
- `SHOOT_NAMESPACE` — the garden-side project namespace (e.g. `garden-compute`).
- `SHOOT_NAME` — the shoot name (e.g. `cc-b1-qa-de-1`).

Steps:

1. **Patch the zone annotation** on the CP namespace. This is the
   value `gardener-resource-manager` reads to stamp node-affinity
   on every CP pod.
2. **Trigger a shoot reconciliation** so Gardener re-renders
   downstream resources that depend on CP AZ (Istio routes, DNS
   records if `zonalIngress` is enabled, etc.).
3. **Roll non-etcd CP deployments** so their pods re-schedule to
   nodes in the new AZ.
4. **Roll etcd** via `etcd-druid` reconcile annotation, which
   respects quorum semantics.
5. **Verify** all CP pods landed in the target AZ and the shoot API
   is reachable.

Expected duration: ~15 minutes wall clock, including waits.
Expected shoot API unavailability: ~30 seconds during kube-apiserver
pod rollover (non-HA CPs only; HA-`node` CPs have zero downtime).

---

## 5. Pre-flight checks <a id="5-preflight"></a>

Run these right before executing. If any check fails, stop and
investigate.

```bash
NS=shoot--compute--cc-b1-qa-de-1
TARGET_AZ=qa-de-1b
SHOOT_NAMESPACE=garden-compute
SHOOT_NAME=cc-b1-qa-de-1

# 1. Shoot is healthy (this is the block for cc-b1 today).
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" get shoot "$SHOOT_NAME" \
  -o jsonpath='{.status.lastOperation.type} | {.status.lastOperation.state} | {.status.lastOperation.progress}%{"\n"}'
# Expected: Reconcile | Succeeded | 100%

# 2. Target AZ is really on the seed.
u8s --context g-qa-de-1 kubectl get seed mgmt-qa-de-1 \
  -o jsonpath='{.spec.provider.zones}{"\n"}'
# TARGET_AZ must appear in this list.

# 3. Seed actually has nodes in the target AZ.
u8s --context mgmt-qa-de-1 kubectl get nodes \
  -l topology.kubernetes.io/zone="$TARGET_AZ" --no-headers | wc -l
# Expected: >= 2 (so we can schedule multiple CP replicas).

# 4. Current annotation is what we think it is (guards against drift).
u8s --context mgmt-qa-de-1 kubectl get ns "$NS" \
  -o jsonpath='{.metadata.annotations.high-availability-config\.resources\.gardener\.cloud/zones}{"\n"}'
# Should print the current (wrong) AZ. Sanity-check before overwriting.

# 5. Etcd backup is fresh.
u8s --context mgmt-qa-de-1 kubectl -n "$NS" get etcd etcd-main \
  -o jsonpath='{.status.lastBackup}{"\n"}'
# Should be within the last hour. Empty or old → stop and investigate.

# 6. Storage is Ceph (not hyperscaler-bound).
u8s --context mgmt-qa-de-1 kubectl -n "$NS" get pvc \
  -o custom-columns=NAME:.metadata.name,SC:.spec.storageClassName
# Every StorageClass should be Ceph-backed (rook-ceph-block or similar),
# NOT gp2 / gp3 / standard / azure-disk / pd-standard etc.

# 7. Confirm nothing is stuck reconciling right now.
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" get shoot "$SHOOT_NAME" \
  -o jsonpath='{.status.conditions[?(@.type=="ControlPlaneHealthy")].status}{"\n"}'
# Expected: True
```

If all seven checks pass, proceed. If any fail, stop.

---

## 6. Full command sequence for `cc-b1-qa-de-1` <a id="6-cc-b1-commands"></a>

**Prerequisite:** `cc-b1-qa-de-1` is no longer in `Create | Failed`.
If it is, do not run this section.

```bash
# --- set variables ---
NS=shoot--compute--cc-b1-qa-de-1
TARGET_AZ=qa-de-1b
SHOOT_NAMESPACE=garden-compute
SHOOT_NAME=cc-b1-qa-de-1

# --- Step 1: patch the annotation ---
u8s --context mgmt-qa-de-1 kubectl annotate ns "$NS" \
  high-availability-config.resources.gardener.cloud/zones="$TARGET_AZ" \
  --overwrite

# --- Step 2: trigger shoot reconciliation ---
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" annotate shoot "$SHOOT_NAME" \
  gardener.cloud/operation=reconcile --overwrite

# Wait for reconciliation to finish before rolling pods.
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" get shoot "$SHOOT_NAME" -w
# Watch for lastOperation.state=Succeeded, then Ctrl+C.

# --- Step 3: roll non-etcd CP deployments ---
for dep in $(u8s --context mgmt-qa-de-1 kubectl -n "$NS" get deploy -o name \
              | grep -v -E 'etcd|druid'); do
  echo "Rolling $dep"
  u8s --context mgmt-qa-de-1 kubectl -n "$NS" rollout restart "$dep"
  u8s --context mgmt-qa-de-1 kubectl -n "$NS" rollout status "$dep" --timeout=5m
done

# --- Step 4: roll etcd via etcd-druid ---
# etcd-main first, wait for it to be healthy, then etcd-events.
u8s --context mgmt-qa-de-1 kubectl -n "$NS" annotate etcd etcd-main \
  gardener.cloud/operation=reconcile --overwrite

# Wait for etcd-main to be rolled and healthy.
u8s --context mgmt-qa-de-1 kubectl -n "$NS" get pods \
  -l app.kubernetes.io/name=etcd,app.kubernetes.io/instance=etcd-main -w
# Watch until 2/2 Ready, then Ctrl+C.

u8s --context mgmt-qa-de-1 kubectl -n "$NS" annotate etcd etcd-events \
  gardener.cloud/operation=reconcile --overwrite

u8s --context mgmt-qa-de-1 kubectl -n "$NS" get pods \
  -l app.kubernetes.io/name=etcd,app.kubernetes.io/instance=etcd-events -w
```

---

## 7. Verification <a id="7-verification"></a>

Run all four blocks. Expected results are called out in each.

```bash
# 1. Every CP pod is on a node in the target AZ.
u8s --context mgmt-qa-de-1 kubectl -n "$NS" get pods \
  -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName --no-headers \
  | while read pod node; do
      [ -n "$node" ] || continue
      zone=$(u8s --context mgmt-qa-de-1 kubectl get node "$node" \
             -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}')
      echo "  $pod  node=$node  zone=$zone"
    done
# Every zone should read qa-de-1b. Any zone that reads qa-de-1a → investigate.

# 2. Namespace annotation is what we set.
u8s --context mgmt-qa-de-1 kubectl get ns "$NS" \
  -o jsonpath='{.metadata.annotations.high-availability-config\.resources\.gardener\.cloud/zones}{"\n"}'
# Expected: qa-de-1b

# 3. Shoot lastOperation returned to healthy.
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" get shoot "$SHOOT_NAME" \
  -o jsonpath='{.status.lastOperation.type} | {.status.lastOperation.state} | {.status.lastOperation.progress}%{"\n"}'
# Expected: Reconcile | Succeeded | 100%

# 4. Shoot API is reachable end to end.
u8s --context "$SHOOT_NAME" kubectl get --raw='/healthz'
# Expected: ok

# 5. Nodes on the shoot itself are still Ready.
u8s --context "$SHOOT_NAME" kubectl get nodes
# All Ready. Zones on shoot nodes should still be qa-de-1b (unchanged).
```

---

## 8. Rollback if something goes wrong <a id="8-rollback"></a>

If verification fails (CP pods stuck Pending, apiserver unreachable,
shoot goes into `Failed`), roll back:

```bash
# 1. Restore the old annotation.
u8s --context mgmt-qa-de-1 kubectl annotate ns "$NS" \
  high-availability-config.resources.gardener.cloud/zones=qa-de-1a \
  --overwrite

# 2. Trigger reconcile again.
u8s --context g-qa-de-1 kubectl -n "$SHOOT_NAMESPACE" annotate shoot "$SHOOT_NAME" \
  gardener.cloud/operation=reconcile --overwrite

# 3. Roll deployments again to pick up the old annotation.
for dep in $(u8s --context mgmt-qa-de-1 kubectl -n "$NS" get deploy -o name); do
  u8s --context mgmt-qa-de-1 kubectl -n "$NS" rollout restart "$dep"
done
```

The Ceph storage backend makes this safe — you're moving pods
between zones, not moving data.

If the shoot won't recover even after rollback: page the on-call
Gardener operator. Do not repeatedly annotate-and-roll — you'll
just churn the CP.

---

## 9. What we deliberately do NOT touch <a id="9-out-of-scope"></a>

- **`cc-b0-qa-de-1`.** CP is already in the intended AZ. No
  migration needed. Its unrelated `Reconcile Failed` state is a
  separate investigation.
- **`cc-d0-qa-de-1`.** Migration impossible on this seed today
  (seed has no `qa-de-1d`). Blocked on AZ-D readiness workstream.
  Manually annotating to `1a` or `1b` would move the CP but move it
  further from the shoot's workers — actively worse than today.
- **`lh-b-qa-de-1`.** Workerless. Manually pinning it now via
  annotation is technically possible but discouraged:
  - It's already in the "correct" AZ (`1b`) by coincidence.
  - Any manual change here creates precedent for manually managing
    Lighthouse zones, which does not scale to future Lighthouse
    shoots across landscapes.
  - Wait for the mutating-webhook workaround, which will pin all
    current and future Lighthouse shoots by naming convention
    uniformly.

---

## 10. Open follow-up items <a id="10-followups"></a>

### 10.1 Diagnose `cc-b1-qa-de-1` create failure

Owner: KVM/Bedrock / `garden-compute` shoot owner.

Not blocking on PR #12197 merge. Blocks the actual `cc-b1`
migration from this doc.

Steps:

```bash
# What's the last error?
u8s --context g-qa-de-1 kubectl -n garden-compute get shoot cc-b1-qa-de-1 \
  -o jsonpath='{.status.lastErrors[*]}{"\n"}'

# What conditions are Progressing/False?
u8s --context g-qa-de-1 kubectl -n garden-compute get shoot cc-b1-qa-de-1 \
  -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.message}){"\n"}{end}'

# Any events on the CP namespace?
u8s --context mgmt-qa-de-1 kubectl -n shoot--compute--cc-b1-qa-de-1 get events \
  --sort-by='.lastTimestamp' | tail -20
```

### 10.2 Diagnose `cc-b0-qa-de-1` reconcile failure

Owner: same as above.

Same diagnostic pattern as §10.1. Since this shoot's CP is already
aligned, its issue is unrelated to #943 but may become visible
during any post-merge verification.

### 10.3 AZ-D readiness (blocks `cc-d0-qa-de-1` migration)

Owner: Compute team + Metal team + Gardener seed operator.

Prerequisites, in order:
1. Confirm `qa-de-1d` network stability is remediated.
2. Add nodes back in `qa-de-1d` to `mgmt-qa-de-1`'s worker pool
   (via the shoot manifest for `mgmt-qa-de-1` in `cc/kube-secrets`).
3. Wait for those nodes to be `Ready`.
4. Add `qa-de-1d` to `Seed.spec.provider.zones` (via the
   `ManagedSeed`'s `seedConfig` — same file as this PR touches).
5. Verify `Seed.spec.provider.zones` shows all three zones on
   `mgmt-qa-de-1`.
6. Migrate `cc-d0-qa-de-1`'s CP using Recipe A with
   `TARGET_AZ=qa-de-1d`.

### 10.4 Lighthouse workaround (blocks `lh-*` alignment)

Owner: this task's successor / whoever picks up the follow-up PR.

Design and ship a mutating admission webhook on `mgmt-*` seeds that
watches `shoot--*` namespace creations and sets the
`…/zones` annotation from the shoot name (for shoots matching
`lh-<az>-<region>-*` naming). See
[`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
§8.2 for the design outline.

Not blocking on PR #12197.

### 10.5 Flip qa-de-1 from `Prefer` to `Enforce`

Owner: this task's successor.

Prerequisites:
- 10.3 (AZ-D readiness) done, so `cc-d0` can schedule.
- All shoots on `mgmt-qa-de-1` verified to have worker zones that
  intersect `Seed.spec.provider.zones`.
- Confirmed with Dmitri / KVM team that `Enforce` semantics are
  acceptable for the landscape.

Then:
- New PR against `sapcc/helm-charts` setting
  `mgmtShoots.qa-de-1.zoneSelection: Enforce` in the downstream
  values file (in `cc/kube-secrets`).

Not blocking on PR #12197.

---

## Appendix — cross-references

- [`gardener-architecture.md`](./gardener-architecture.md) — the
  garden / runtime / seed / shoot layers.
- [`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
  — umbrella design of #943 and rollout plan.
- [`gardener-qa-de-1-cp-az-findings.md`](./gardener-qa-de-1-cp-az-findings.md)
  — live evidence and per-shoot analysis for qa-de-1.
- [`sapcc/helm-charts#12197`](https://github.com/sapcc/helm-charts/pull/12197)
  — the PR this doc's plan runs after.
