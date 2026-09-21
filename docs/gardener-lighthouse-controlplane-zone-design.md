# Lighthouse CP zone pinning — `Shoot.spec.controlPlane.zone`: scope, immutability & migration

> **Status:** Design note capturing the upstream discussion with Rafael Franzke
> and Dmitri Fedotov on closing the workerless-shoot (Lighthouse) gap of
> [`cc/unified-kubernetes#943`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/943).
> Feeds the decision on what to ask upstream Gardener to build.
>
> **Date:** 2026-07-29.
>
> **See also:** [`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
> (umbrella design), [`gardener-qa-de-1-cp-az-findings.md`](./gardener-qa-de-1-cp-az-findings.md)
> (live state), [`gardener-qa-de-1-cp-migration-plan.md`](./gardener-qa-de-1-cp-migration-plan.md)
> (migration runbook).

---

## TL;DR

- The worker-bearing KVM shoots are already solved by `Seed.spec.settings.zoneSelection: Prefer`.
- The remaining gap is **workerless Lighthouse shoots** — `zoneSelection` can't
  place them (no worker pool → empty zone intersection → random fallback).
- Agreed upstream direction: a new **`Shoot.spec.controlPlane.zone`** field,
  **gated by the CloudProfile** (only valid on own-infrastructure like
  OpenStack/metal, where zone names map to real physical zones).
- **Scope: workerless-only.** Dmitri argued away the "all shoots / AZ-maintenance
  flip" use case (see §3), so we do **not** need it for worker-bearing shoots.
  This also sidesteps the etcd-volume-migration problem that an all-shoots mutable
  field would create.
- **Immutability nuance:** a strictly create-only immutable field is fine for
  *steady state* but leaves a **migration gap for the ~9 Lighthouse shoots that
  already exist**. Recommend **"set-once" semantics** (unset → value allowed on
  update; value → different value rejected) so existing shoots can adopt the field
  without a delete-recreate.
- **Why set-once is free for us:** Lighthouse etcd sits on `rook-ceph-block`
  (Ceph), which is **not zone-bound** — verified on `mgmt-qa-de-1`. So setting the
  field on an existing Lighthouse re-homes its CP cleanly, with no disk migration.

---

## 1. Where the gap is

### 1.0 The KVM architecture that drives all of this

The requirement comes from how the KVM compute platform is structured
(Fabian's original description in the thread):

> "These shoots are dedicated to a single availability zone. In other words,
> each KVM shoot contains hypervisors from only one AZ. For scaling reasons, we
> expect to run multiple such KVM shoots per AZ, potentially five or more."

Translated:

- **Each KVM shoot is dedicated to one AZ.** A given shoot is "the AZ-b cluster"
  or "the AZ-a cluster" — never spanning two.
- **Its worker nodes are hypervisors** (the physical servers that run customer
  VMs), and **all of them sit in that one AZ.** e.g. `cc-b0-qa-de-1`'s
  hypervisors are all in `qa-de-1b`; none in `1a` or `1d`.
- **Multiple KVM shoots per AZ, 5+.** An AZ isn't served by a single cluster.
  As hypervisor capacity in an AZ grows, they add more *shoots* in that AZ
  (`cc-b0`, `cc-b1`, `cc-b2`, …), all AZ-local. Scaling = more per-AZ shoots,
  not one giant cluster.

Two design reasons behind this:

1. **AZ-locality for blast-radius isolation.** Keeping each shoot's hypervisors
   in a single AZ means an AZ outage only takes down the shoots belonging to
   that AZ; other AZs' clusters keep running. If a shoot's hypervisors were
   spread across AZs, one AZ failure would partially cripple every shoot.
2. **Multiple small shoots instead of one big one per AZ.** A single Kubernetes
   cluster has practical size limits (etcd size, apiserver load, single-cluster
   blast radius). Sharding an AZ's hypervisors across several smaller shoots
   keeps each manageable and limits the blast radius of any one shoot's control
   plane failing to a slice of the AZ, not the whole AZ.

```
Region qa-de-1
├── AZ qa-de-1a
│     ├── KVM shoot cc-a0   (hypervisors: all in 1a)
│     ├── KVM shoot cc-a1   (hypervisors: all in 1a)
│     └── … up to 5+ shoots
├── AZ qa-de-1b
│     ├── KVM shoot cc-b0   (hypervisors: all in 1b)   ← ~12 worker pools, many hypervisors
│     ├── KVM shoot cc-b1   (hypervisors: all in 1b)
│     └── … up to 5+ shoots
└── AZ qa-de-1d
      ├── KVM shoot cc-d0   (hypervisors: all in 1d)
      └── … up to 5+ shoots
```

**Why this drives #943:**

- Because each KVM shoot is AZ-local (workers all in one AZ), Gardener can derive
  the CP zone from the worker-pool zones and pin it to the matching AZ. That's
  exactly what `zoneSelection: Prefer` does — and why it "just works" for the KVM
  shoots.
- Because there are **5+ KVM shoots per AZ**, something has to give a single,
  unified view of *all* the compute in one AZ across those separate shoots. That
  "something" is the **Lighthouse** cluster — one per AZ, aggregating the state of
  every KVM shoot in that AZ. Which is why Lighthouse must also be pinned to the
  same AZ, and — being workerless — is the part `zoneSelection` can't handle.

### 1.1 The gap

| Shoot class | Placement mechanism | Status |
| --- | --- | --- |
| KVM compute (workers in 1 AZ) | `Seed.spec.settings.zoneSelection: Prefer` derives CP zone from worker-pool zones | ✅ solved |
| Lighthouse (workerless, per-AZ coordinator) | none — no worker zones to derive from; `Prefer` falls back to random | ❌ gap |

Lighthouse is a workerless shoot providing a per-AZ coordination API for the KVM
hypervisors in that AZ. Its clients (the hypervisors) live in one AZ, so its CP
must be pinned to that same AZ — but Gardener has no worker-pool signal to infer
it. The intent lives only in the shoot name (`lh-<az>-<region>`), which Gardener
doesn't parse.

Upstream consensus (Rafael, Dmitri): close it with a first-class
`Shoot.spec.controlPlane.zone` field, gated by an explicit opt-in in the
CloudProfile. `Shoot.spec.controlPlane` today only has `HighAvailability` — the
`zone` field is net-new (confirmed in `pkg/apis/core/v1beta1/types_shoot.go`).

---

## 2. Why the CloudProfile gate (Rafael's condition)

The field only makes sense on infrastructure where **we own the zone-name → physical-zone mapping**: OpenStack, bare metal, sovereign clouds. On hyperscalers (AWS/Azure/GCP) AZ names are randomized per account — `eu-1a` in one account is not the same physical zone as `eu-1a` in another — so pinning to a named zone there is meaningless or misleading.

Gating the field behind a CloudProfile opt-in means only own-infrastructure CloudProfiles expose it; hyperscaler CloudProfiles never do, so hyperscaler customers can't foot-gun themselves. Same design logic that put `zoneSelection` on the `Seed` (operator-controlled) rather than the `Shoot` (customer-controlled).

Dmitri confirmed the AZ names already exist in the openstack CloudProfile (`eu-de-1a/1b/1d`), on par with the ironcore-metal CloudProfile — so the gate prerequisite is already satisfied for Lighthouse.

> Side note: Lighthouse shoots currently declare `provider.type: openstack` even
> though they're workerless and sit on a metal seed. Nobody recalls exactly why,
> but it doesn't block anything — the openstack CloudProfile carries the right AZ
> names, so the CloudProfile gate works as-is.

---

## 3. Why scope is workerless-only (the "all shoots" case was argued away)

The only reason to want `.spec.controlPlane.zone` on **worker-bearing** shoots was a hypothetical "flip the CP out of an AZ going into planned maintenance" use case. Dmitri's reasoning (which holds up) closes it:

- **Multi-AZ shoots** → covered by **zone-level HA** (`failureToleranceType: zone`). Their CP is already spread across all AZs, so an AZ maintenance/outage is survived by redundancy. Nothing to "flip." (Caveat: needs a 3-AZ region for proper zone-HA; dual-AZ regions can't do it well — a known limitation, not something a flip-field would fix.)
- **AZ-local shoots** (KVM / Lighthouse) → failover is deliberately handled at the **workload level** — there are independent per-AZ stacks (AZ-A KVM + Lighthouse, AZ-B KVM + Lighthouse, …). If AZ-A goes down, AZ-A's stack is *supposed* to go down; AZ-B keeps serving. Relocating an AZ-local CP to another AZ would *violate* the isolation design, not help it.

So neither shoot class needs the maintenance-flip. Scope collapses cleanly to **workerless-only**, which also means we never confront the etcd-migration problem an all-shoots mutable field would create (see §4).

---

## 4. Immutability & the migration gap

### 4.1 The tension

"Immutable is fine" is true for **steady state** — a Lighthouse's zone is set once at creation and never flipped. But strictly create-only immutability leaves a **migration gap**: the ~9 Lighthouse shoots that **already exist** (8× eu-de-*, 1× qa-de-1) can't have an immutable field added to them after the fact.

### 4.2 Why mutability is normally dangerous (and why it isn't for us)

The reason Gardener's existing CP-zone logic is effectively one-shot is **not** an API immutability rule — it's the physical fact that **etcd's PV is usually zone-bound**. `calculateShootZones` (in `pkg/gardenlet/operation/botanist/namespaces.go`) inspects existing PVCs/PVs and *pins the CP zone to wherever the volumes already live*, precisely so it never strands a disk. Its own comment:

> "existing clusters might already run in multiple zones. In particular, if they
> have created their volumes in multiple zones already, we cannot change this
> unless we delete and recreate the disks. This is nothing we want to do
> automatically…"

So moving an existing CP's zone means an etcd backup-restore + downtime — which is why an "all shoots + mutable" field would be a big, risky feature. **But** on our seeds the etcd PV is **Ceph-backed and not zone-bound** (verified — see §4.4), so this constraint doesn't apply to us.

### 4.3 The three migration paths for existing Lighthouse shoots

| Path | Mechanism | Needs upstream? | Disruptive? | Notes |
| --- | --- | --- | --- | --- |
| **A. Delete + recreate** | Set `zone` in manifest, delete the Lighthouse, recreate it | No (works with strict create-only immutable) | Brief per-AZ coordination-API outage | OK only if Lighthouse etcd state is disposable/rebuildable from hypervisor re-registration — **confirm with Lighthouse owners** |
| **B. "Set-once" field** | Field allows unset → value on update, but rejects value → different-value | Yes — needs Rafael to implement set-once (not strict create-only) | No recreate; CP re-homes on the update | **Recommended.** Free for us because Ceph etcd isn't zone-bound (§4.4). Still prevents arbitrary later flips. |
| **C. Manual annotation (interim, today)** | Set `high-availability-config.resources.gardener.cloud/zones` on the CP namespace, roll CP pods | No (available now, pre-upstream) | Brief CP pod restart | The stop-gap until the field ships. For `lh-b-qa-de-1` it's currently a no-op (already in `1b`). |

### 4.4 Verified: Lighthouse etcd is zone-agnostic on our seeds

On `mgmt-qa-de-1`, `shoot--compute--lh-b-qa-de-1`:

```
$ ukg --context mgmt-qa-de-1 -n shoot--compute--lh-b-qa-de-1 pvc
  main-etcd-etcd-main-0        sc=rook-ceph-block
  etcd-events-etcd-events-0    sc=rook-ceph-block

$ ukg --context mgmt-qa-de-1 pv <etcd-main-pv> -o jsonpath='{.spec.nodeAffinity}'
  <empty — no zone nodeAffinity>

$ ukg --context mgmt-qa-de-1 sc rook-ceph-block -o jsonpath='{.allowedTopologies}'
  <empty — no topology constraint>
```

Both etcd PVs use `rook-ceph-block`, the PV has no zone `nodeAffinity`, and the StorageClass has no `allowedTopologies`. So a CP zone change re-homes cleanly — no disk migration, no restore-from-backup. This is what makes Path B safe *for us* even though it would be unsafe on a hyperscaler seed.

---

## 5. Recommendation

Ask Rafael for:

1. **`Shoot.spec.controlPlane.zone`**, **workerless-only**, **CloudProfile-gated.**
2. **"Set-once" semantics** rather than strict create-only immutability
   (unset → value allowed on update; value → different value rejected). This:
   - gives a clean migration path for the existing Lighthouse shoots (no
     delete-recreate of live per-AZ coordinators),
   - still prevents arbitrary later flips (the thing immutability protects), and
   - is safe for us because our Ceph etcd volumes aren't zone-bound.
3. If set-once is more work than he wants, **strict create-only immutable is
   acceptable** — we fall back to **Path A (delete + recreate)** for the existing
   Lighthouse shoots, *provided* their etcd state is rebuildable (to confirm with
   the Lighthouse owners).

Either way, **Path C (manual annotation)** remains the interim mechanism until the
field ships, and is already a no-op for `lh-b-qa-de-1`.

### Open items

- [ ] Confirm with Lighthouse owners whether Lighthouse etcd state is disposable
      (decides whether Path A is acceptable, i.e. whether strict-immutable is OK).
- [ ] Decide set-once (Path B) vs strict-immutable+recreate (Path A) and put it to
      Rafael.
- [ ] Track the upstream `Shoot.spec.controlPlane.zone` PR once opened.
- [ ] Until the field ships: keep `lh-*` shoots pinned via the annotation (Path C),
      guarded by the drift alert (see [`gardener-qa-de-1-cp-az-findings.md`](./gardener-qa-de-1-cp-az-findings.md) §7).

---

## 6. Upstream code references

- `pkg/apis/core/v1beta1/types_seed.go` — `SeedSettingZoneSelection` struct (`.Mode`).
- `pkg/apis/core/v1beta1/types_shoot.go` — `ControlPlane` struct (today only `HighAvailability`; no `Zone` field yet).
- `pkg/gardenlet/operation/botanist/namespaces.go` — `calculateShootZones`: the `Prefer`/`Enforce` intersection logic **and** the PVC/PV zone-pinning that constrains CP-zone changes to existing volume zones.
- `pkg/scheduler/controller/shoot/reconciler.go` — scheduler filters `Enforce` seeds with no zone overlap, prefers `Prefer` seeds.
- `pkg/api/core/validation/{shoot,backupbucket}.go` — `apivalidation.ValidateImmutableField` precedent (e.g. `seedName` is immutable) for how a new immutable/set-once field would be enforced.
