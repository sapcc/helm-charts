# qa-de-1 CP AZ-placement findings — evidence for #943

> **Status:** Analysis note, feeds directly into the implementation
> decision for [`cc/unified-kubernetes#943`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/943)
> ("[Gardener] Dataplane clusters - Kubernetes API AZ local").
>
> **Audience:** engineers who want ground-truth evidence for the
> state of shoot CP placement on the `mgmt-qa-de-1` seed today,
> including which shoots are currently misplaced, which have
> impossible-to-align configurations, and what Lighthouse
> shoots are supposed to be pinned to and why.
>
> **See also:** [`gardener-architecture.md`](./gardener-architecture.md)
> for a refresher on garden/runtime/seed/shoot layers,
> [`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
> for the umbrella design that this note plugs into.

---

## TL;DR

Snapshot of the four shoots currently hosted on `mgmt-qa-de-1`:

| Shoot           | Worker zone (intent) | CP annotation `…/zones` (today) | Actual kube-apiserver AZ | Aligned?                                             |
| --------------- | -------------------- | ------------------------------- | ------------------------ | ---------------------------------------------------- |
| `cc-b0-qa-de-1` | `qa-de-1b`           | `qa-de-1b`                      | `qa-de-1b`               | ✅ correct **by luck**                               |
| `cc-b1-qa-de-1` | `qa-de-1b`           | `qa-de-1a`                      | `qa-de-1a`               | ❌ **misplaced live today** — cross-AZ traffic     |
| `cc-d0-qa-de-1` | `qa-de-1d`           | `qa-de-1a`                      | `qa-de-1a`               | ⚠ **impossible** — seed has no `1d`                 |
| `lh-b-qa-de-1`  | *(workerless)*       | `qa-de-1b`                      | `qa-de-1b`               | ✅ correct **by luck** — should be `1b` (see §4)    |

Findings that shape the PR:

1. **`cc-b1-qa-de-1` is currently misplaced.** Its CP kube-apiserver
   is running in AZ `1a` even though the shoot's workers are in AZ
   `1b`. This is a real, live example of the problem #943 exists
   to fix — not just a hypothetical benefit.
2. **`cc-d0-qa-de-1`'s intent is `qa-de-1d`, but the seed had to be
   pulled out of `1d`.** The seed previously included nodes in
   `qa-de-1d` but they were removed due to underlying network
   instability that made the seed unhealthy. The Compute team is
   separately working on re-deploying `cc-d0-qa-de-1` in AZ-D once
   `1d` is stable enough to re-add. Confirmed on Slack — see §5.4.
3. **`lh-b-qa-de-1` is workerless but has a target AZ** — it is
   supposed to serve KVM compute in AZ `1b`. Naming convention and
   cross-landscape evidence make the intended AZ unambiguous. See
   §7.
4. **The recommended first PR is `zoneSelection: Prefer`.** It fixes
   `cc-b1` on next reconcile, leaves `cc-d0` unchanged (no
   regression, awaiting AZ-D readiness work), leaves `lh-b`
   unchanged (still correct by luck), introduces zero new failure
   modes. Flipping to `Enforce` is a follow-up gated on AZ-D
   readiness (see §5.4 and §8).

---

## 1. Live snapshot — annotation vs. reality vs. intent <a id="1-live-snapshot"></a>

This is the ground-truth table for `mgmt-qa-de-1` today, drawn from
live queries against the garden and seed. It is what the rest of
this doc is analyzing.

| Shoot           | Worker-pool zones (intent, from Shoot spec) | Annotation `…/zones` on CP namespace (seed) | Actual AZ of `kube-apiserver` pod | Aligned to intent? |
| --------------- | ------------------------------------------- | ------------------------------------------- | --------------------------------- | ------------------ |
| `cc-b0-qa-de-1` | `qa-de-1b`                                  | `qa-de-1b`                                  | `qa-de-1b`                        | ✅ **yes, but by luck** |
| `cc-b1-qa-de-1` | `qa-de-1b`                                  | `qa-de-1a`                                  | `qa-de-1a`                        | ❌ **no — live misplacement** |
| `cc-d0-qa-de-1` | `qa-de-1d`                                  | `qa-de-1a`                                  | `qa-de-1a`                        | ⚠ **impossible on this seed** (§3) |
| `lh-b-qa-de-1`  | *(workerless)*                              | `qa-de-1b`                                  | `qa-de-1b`                        | ✅ **yes, by luck; should be `1b` — see §7** |

### 1.1 What each row means

**`cc-b0-qa-de-1` — correct, but for the wrong reason.**
The shoot declares its workers in `1b`, the annotation says `1b`,
the kube-apiserver runs in `1b`. Everything is aligned. But this
alignment is a coincidence: `zoneSelection` is unset on the seed,
so Gardener rolled a random zone at namespace creation and
happened to pick `1b`. Any re-create of the CP namespace could
undo it. This is not stability — it's uptime luck.

**`cc-b1-qa-de-1` — live misplacement, exactly the failure mode #943 targets.**
Workers declared in `1b`; annotation and CP running in `1a`.
Every kubelet on this shoot's workers is talking cross-AZ to its
own apiserver right now. Every `LIST`, `WATCH`, and status update
goes `1b → 1a → 1b`. It hasn't crashed anything, but it *is* the
concrete symptom of #943 in production form. `zoneSelection:
Prefer` will fix this shoot on the next namespace re-create; a
manual annotation patch (see the AZ-placement doc §8.3) fixes it
now.

**`cc-d0-qa-de-1` — impossible to satisfy on this seed.**
Workers declared in `1d`; seed `spec.provider.zones` is
`["qa-de-1a","qa-de-1b"]`; seed has zero physical nodes in `1d`.
There is no annotation value that would result in the CP running
in `1d`, because there is nowhere in this seed to schedule it.
The current annotation is `1a` (Gardener's random pick from the
seed's zone list). See §3 for what to do about it.

**`lh-b-qa-de-1` — workerless, but with an unambiguous intended AZ.**
Workerless shoots have no `spec.provider.workers[*].zones` for
Gardener to look at. But the shoot name (`lh-**b**-qa-de-1`) and
its purpose (§7) both say `qa-de-1b`. The annotation and the pod
both landed on `1b` — again by luck of the random pick. The
Lighthouse case is discussed in depth in §7.

### 1.2 One-liner to reproduce

```bash
# For each shoot on mgmt-qa-de-1, print worker-zones, annotation, and actual apiserver AZ.
u8s --context g-qa-de-1 kubectl get shoot -A -o json \
  | jq -r '.items[]
           | select(.spec.seedName=="mgmt-qa-de-1")
           | "\(.metadata.namespace)/\(.metadata.name)\tworkers=\(
                [.spec.provider.workers[]?.zones[]?] | unique | join(",")
              )"'
# then, on the seed:
for ns in $(u8s --context mgmt-qa-de-1 kubectl get ns -o name | grep '^namespace/shoot--' | cut -d/ -f2); do
  ann=$(u8s --context mgmt-qa-de-1 kubectl get ns "$ns" \
        -o jsonpath='{.metadata.annotations.high-availability-config\.resources\.gardener\.cloud/zones}')
  node=$(u8s --context mgmt-qa-de-1 kubectl get pod -n "$ns" -l role=apiserver \
        -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
  zone=$(u8s --context mgmt-qa-de-1 kubectl get node "$node" \
        -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' 2>/dev/null)
  echo "  $ns  annotation=$ann  pod-zone=$zone"
done
```

Expected output at time of writing (2026-07-05):

```
compute/cc-b0-qa-de-1   workers=qa-de-1b
compute/cc-b1-qa-de-1   workers=qa-de-1b
compute/cc-d0-qa-de-1   workers=qa-de-1d
compute/lh-b-qa-de-1    workers=

shoot--compute--cc-b0-qa-de-1   annotation=qa-de-1b   pod-zone=qa-de-1b
shoot--compute--cc-b1-qa-de-1   annotation=qa-de-1a   pod-zone=qa-de-1a
shoot--compute--cc-d0-qa-de-1   annotation=qa-de-1a   pod-zone=qa-de-1a
shoot--compute--lh-b-qa-de-1    annotation=qa-de-1b   pod-zone=qa-de-1b
```

### 1.3 Note on the annotation format

The annotation values today are bare strings (`qa-de-1a`) rather
than list-style (`["qa-de-1a"]` or `qa-de-1a,qa-de-1b`) that some
newer Gardener docs describe. Both forms are accepted by
`gardener-resource-manager` in the versions we run; the bare-string
form is what Gardener itself writes when it picks a random zone.
After enabling `zoneSelection`, verify on the first test shoot
that the annotation is still valid (single string or list, both
work).

---

## 2. The finding, verified <a id="2-finding-verified"></a>

Three `kubectl` queries, three facts about the `cc-d0-qa-de-1` case
(the row that makes the seed's zone list incompatible with the
shoot's worker zones):

Three `kubectl` queries, three facts.

### Fact 1 — the shoot declares workers in `qa-de-1d`

```
$ u8s --context g-qa-de-1 kubectl -n garden-compute \
    get shoot cc-d0-qa-de-1 \
    -o jsonpath='{range .spec.provider.workers[*]}pool={.name} zones={.zones}{"\n"}{end}'

pool=bb271-gp zones=["qa-de-1d"]
```

The shoot has exactly one worker pool named `bb271-gp`, and its
`zones` array contains one entry: `qa-de-1d`.

### Fact 2 — the seed's zone list has no `qa-de-1d`

```
$ u8s --context g-qa-de-1 kubectl get seed mgmt-qa-de-1 \
    -o jsonpath='{.spec.provider.zones}'

["qa-de-1a","qa-de-1b"]
```

The seed's provider spec only advertises two zones: `1a`, `1b`.

### Fact 3 — no seed node lives in `qa-de-1d`

```
$ u8s --context mgmt-qa-de-1 kubectl get nodes -L topology.kubernetes.io/zone

NAME                                                   STATUS   ROLES    ZONE
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1a-z1-7cdcb-4dpzp   Ready    worker   qa-de-1a
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1a-z1-7cdcb-rjd2k   Ready    worker   qa-de-1a
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1a-z1-7cdcb-tj2vs   Ready    worker   qa-de-1a
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1b-z1-7f545-4d8lk   Ready    worker   qa-de-1b
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1b-z1-7f545-cql9c   Ready    worker   qa-de-1b
shoot--cp--mgmt-qa-de-1-mgmt-qa-de-1b-z1-7f545-f5gt6   Ready    worker   qa-de-1b
```

Zero nodes in `qa-de-1d`. The seed's zone list is not just a typo in
config — the physical reality matches. This seed physically has no
presence in `qa-de-1d`.

---

## 3. Picture: the mismatch in one diagram

```
Region  qa-de-1
════════════════════════════════════════════════════════════════════

AZ qa-de-1a          AZ qa-de-1b          AZ qa-de-1c          AZ qa-de-1d
┌───────────┐        ┌───────────┐        ┌───────────┐        ┌───────────┐
│           │        │           │        │           │        │           │
│           │        │           │        │           │        │           │
└───────────┘        └───────────┘        └───────────┘        └───────────┘


       Seed  mgmt-qa-de-1  spec.provider.zones = [1a, 1b]
       ─────────────────────────────────────────────────
       ┌─────────────────────────┐
       │  node in 1a  ✅          │
       │  node in 1a  ✅          │
       │  node in 1a  ✅          │
       │  node in 1b  ✅          │       (no seed nodes in 1c or 1d)
       │  node in 1b  ✅          │
       │  node in 1b  ✅          │
       └─────────────────────────┘


       Shoots  spec.provider.workers[*].zones
       ─────────────────────────────────────
                                                              cc-d0-qa-de-1
                            cc-b*-qa-de-1                     wants workers
                            wants workers                     HERE
                            HERE                              ▼
                            ▼                        ┌─────────────────┐
                    ┌─────────────────┐              │  qa-de-1d  ❓    │
                    │  qa-de-1b  ✅   │              └─────────────────┘
                    └─────────────────┘
```

Reading left to right:

- The **region** has four AZs (at least in metal-api's world):
  `1a`, `1b`, `1c`, `1d`.
- The **seed** `mgmt-qa-de-1` only participates in `1a` and `1b`. It
  has no node in `1c` or `1d`. So when it "hosts" a shoot's control
  plane, the pods physically end up on nodes in `1a` or `1b`.
- The **shoots** declare where they want their **workers**:
  - `cc-b0`, `cc-b1` → `qa-de-1b` — matches a zone the seed has.
  - `cc-d0` → `qa-de-1d` — a zone **the seed does not have**.

The mismatch is entirely about `cc-d0-qa-de-1`. Everything else is
fine.

---

## 4. Picture: what `zoneSelection` does to this mismatch

Recall from [`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
§5.1: `zoneSelection` on the seed changes how Gardener decides where
each shoot's CP pods run. It looks at the **intersection** of the
shoot's worker zones and the seed's zones.

### Today — no `zoneSelection` set (default random)

```
Shoot cc-d0-qa-de-1  worker zones: [1d]
Seed  mgmt-qa-de-1   provider zones: [1a, 1b]

                random pick from seed zones (ignores workers)
                ─────────────────────────────────────────────
Result:   CP pod runs on 1a or 1b (whichever Gardener rolled)

Status:   Scheduling succeeds. Placement is suboptimal but nothing
          fails because of zone selection.
```

This is the pre-#943 world. It's why the shoot is *scheduled* at all
today, even with the mismatch.

### With `zoneSelection: Prefer`

```
Shoot cc-d0-qa-de-1  worker zones: [1d]
Seed  mgmt-qa-de-1   provider zones: [1a, 1b]

                intersection = [1d] ∩ [1a, 1b] = ∅
                    ↓
                Prefer says: "empty? fall back to random"
                ─────────────────────────────────────────────
Result:   CP pod runs on 1a or 1b (same as today)

Status:   Scheduling succeeds. Same suboptimal placement as before.
          NO REGRESSION.

Meanwhile for cc-b0 / cc-b1:
        intersection = [1b] ∩ [1a, 1b] = [1b]
        ─────────────────────────────────────
Result:   CP pod PINNED to 1b  ✅
```

**Prefer** is the "best-effort" mode. Mismatched shoots keep their
current random placement; matching shoots get correctly pinned.

### With `zoneSelection: Enforce`

```
Shoot cc-d0-qa-de-1  worker zones: [1d]
Seed  mgmt-qa-de-1   provider zones: [1a, 1b]

                intersection = [1d] ∩ [1a, 1b] = ∅
                    ↓
                Enforce says: "empty? refuse."
                ─────────────────────────────────────────────
Gardener scheduler:
  - filters out mgmt-qa-de-1 as a candidate seed for cc-d0-qa-de-1
  - qa-de-1 landscape has no other metal seed
  - cc-d0-qa-de-1 becomes PermanentlyUnschedulable

Result:   Reconcile Error, cluster cannot be created or migrated.
          NEW FAILURE MODE we didn't have before.

Meanwhile for cc-b0 / cc-b1:
        intersection = [1b] ∩ [1a, 1b] = [1b]
        ─────────────────────────────────────
Result:   CP pod PINNED to 1b  ✅
```

**Enforce** is the strict mode. It fixes the placement for matching
shoots *and* blocks mismatched shoots from being scheduled at all.

---

## 5. Why the mismatch exists — three possible stories

I do not know which is true. Someone with KVM/Bedrock context needs
to confirm.

### Story A — the seed is behind on catching up

The KVM compute layer has expanded into `qa-de-1d` recently, but the
`mgmt-qa-de-1` seed cluster was not extended to have nodes there. So
metal-api and the shoot manifest correctly reference `1d`, but the
seed operator hasn't provisioned seed capacity in `1d` yet.

**Signal that supports this:** `qa-de-1c` is also missing from the
seed; if AZ expansion is genuinely incremental, this is consistent.

**Fix:** provision seed nodes in `qa-de-1d` (and probably `1c`), add
those zones to `Seed.spec.provider.zones`. Then `Enforce` works.

### Story B — the shoot is misconfigured

Someone wrote `qa-de-1d` in the shoot manifest by mistake — copy-paste
from a different region, or a template typo. The KVM layer never
intended workers in `1d`.

**Signal that supports this:** `cc-d0-qa-de-1` is *currently failing*
independently of the zone question (`Reconcile Failed 79%`). Broken
shoots often stay broken because they are wrong in multiple ways.

**Fix:** change the shoot's worker pool zones to `1a` or `1b`. Then
`Enforce` works.

### Story C — a deliberate experiment

Someone is prototyping a compute presence in `1d` before the seed
side is ready. They know the shoot is failing; that is expected.

**Signal that supports this:** the pool name `bb271-gp` is
metal-specific and does not obviously indicate an experiment, but
that's how experiments often look on this landscape.

**Fix:** clarify intent with the shoot owner; may require the seed
to be extended (Story A path) once the experiment is ratified.

### 5.4 Resolution: Story A confirmed <a id="5-4-resolution"></a>

Confirmed on Slack by Dmitri Fedotov (2026-07-05):

> *"That's unfortunately the current state in qa-de-1d — we had to
> disable nodes in AZ-D because there was too much network
> instability that caused the Seed to be unhealthy. Compute team
> has a separate ongoing effort to deploy the Shoot
> `cc-d0-qa-de-1` in AZ-D."*

So the reality is a hybrid of **Story A** and **Story C**:

- The seed *previously* had nodes in `qa-de-1d`, but they were
  removed due to underlying network instability that was making
  the seed unhealthy. `qa-de-1d` was dropped from
  `Seed.spec.provider.zones` at that time.
- `cc-d0-qa-de-1` remains declared in `qa-de-1d` because the
  Compute team has an active workstream to re-deploy that shoot
  in AZ-D — presumably once the network conditions in `1d` are
  stable enough to re-add seed capacity there.

This changes nothing about the immediate PR decision, but it does
change the follow-up plan:

- **`Prefer` is definitely the correct starting mode.** `Enforce`
  would strand `cc-d0-qa-de-1` in a scheduling failure until AZ-D
  seed capacity is re-added, which is not on the roadmap for this
  PR's timeline.
- **The path to `Enforce` is now clearly gated.** The prerequisites
  are: (1) `qa-de-1d` seed nodes are re-added and stable, (2)
  `qa-de-1d` is added back into `Seed.spec.provider.zones` on
  `mgmt-qa-de-1`, (3) `cc-d0-qa-de-1`'s PVs are migrated to `1d`
  (Dmitri specifically flagged this as an item to handle). Only
  then does flipping to `Enforce` become safe.
- **A separate follow-up thread will track this.** Dmitri suggested
  spinning off the "flip to Enforce for qa-de-1" discussion into
  its own thread once the AZ-D readiness work has more definition,
  so it doesn't derail the initial `zoneSelection` rollout. This
  doc is that thread's kickoff record.

Related context from Fabian Ruff (same Slack follow-up, addressed
to Tim Usner's earlier alternative proposals):

> *"a) We have quite a few regions with only two availability zones;
> this breaks the promise of HA control planes. That's why we want
> clusters that only manage resources in one AZ to also have the
> control plane run in the same AZ so that an AZ outage will at
> least keep these systems running."*
>
> *"b) The problem is that we are in a bare-metal scenario here and
> creating additional seed clusters doesn't come cheap. We have to
> set aside at least 3 physical nodes; the smallest hardware SAP is
> willing to buy is 768 GB RAM, so creating seeds per availability
> zone in addition to a stretched cluster is economically not
> feasible to address this issue."*

These two points close out the two alternatives Tim had proposed
in the original Slack thread (§2.1 step 10 of
[`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)):

| Tim's alternative                         | Fabian's response, summarized                                                                              |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **(a)** One HA Lighthouse across AZs      | Rejected. Many regions have only 2 AZs, so a zone-spread CP can't achieve real HA against AZ loss anyway.  |
| **(b)** One seed per AZ instead of stretched | Rejected. Bare-metal minimum SKU is 768 GB × 3 nodes; running three seeds per region is not economical.  |

So the design space is confirmed: `zoneSelection` on stretched
seeds (plus, later, a downstream Lighthouse fix) is the only
economically viable path.

---

## 6. Impact on issue #943

The impact is entirely on *which mode we set* and *when*. It does
not change the mechanism, the file to edit, or the rollout target.

```
Decision that #943 has to make
───────────────────────────────
seed  mgmt-qa-de-1
      └── spec.settings.zoneSelection = ?

              ┌──────────────────┬──────────────────┬──────────────────┐
              │       Prefer     │      Enforce     │  Do nothing yet  │
              ├──────────────────┼──────────────────┼──────────────────┤
cc-b0-qa-de-1 │  ✅ pinned to 1b │  ✅ pinned to 1b │  ⚠ random today  │
cc-b1-qa-de-1 │  ✅ pinned to 1b │  ✅ pinned to 1b │  ⚠ random today  │
cc-d0-qa-de-1 │  ⚠ random (as  │  ❌ can't schedule│  ⚠ random today  │
              │     today)      │  (regression)   │                  │
lh-b-qa-de-1  │  ⚠ random —     │  ⚠ random —     │  ⚠ random today  │
              │     workerless  │     workerless  │                  │
              │     (see §6)    │     (see §6)    │                  │
              └──────────────────┴──────────────────┴──────────────────┘
```

- **`Prefer` today** = strict win for `cc-b*`, no regression for
  `cc-d0`. Meets the spirit of #943 (steer CPs to the correct AZ)
  without introducing a new failure mode.
- **`Enforce` today** = strict win for `cc-b*`, but introduces a new
  failure mode on `cc-d0` unless we first resolve the mismatch
  (Story A or Story B). Blocks the PR on someone else's work.
- **Do nothing** = does not make progress on #943.

The recommended path for the first PR is therefore:

1. Enable `zoneSelection: Prefer` on `mgmt-qa-de-1` (and only
   qa-de-1 in this first PR).
2. Track the `cc-d0-qa-de-1` mismatch as a separate follow-up
   ticket: "decide whether to add `qa-de-1d` to the seed or move the
   shoot".
3. Once that follow-up ticket is closed, a second PR flips
   qa-de-1 (and rolls out to other landscapes) from `Prefer` to
   `Enforce`.

---

## 7. Where Lighthouse (`lh-b-qa-de-1`) is supposed to sit — and why <a id="7-lighthouse"></a>

Lighthouse is the trickiest case because Gardener has no data model
for "the intended AZ of a workerless shoot." Yet — as shown in §1 —
each Lighthouse *does* have an unambiguous intended AZ. That
intent lives in three places: the naming convention, the deployment
topology, and the operational purpose. This section documents all
three, so future readers can understand what the correct AZ is even
though Gardener can't see it.

### 7.1 The naming convention encodes the AZ

Lighthouse shoots follow the pattern **`lh-<az-suffix>-<region>`**:

| Shoot           | AZ suffix | Region     | Intended AZ  |
| --------------- | :-------: | ---------- | ------------ |
| `lh-a-eu-de-1`  | `a`       | `eu-de-1`  | `eu-de-1a`   |
| `lh-b-eu-de-1`  | `b`       | `eu-de-1`  | `eu-de-1b`   |
| `lh-d-eu-de-1`  | `d`       | `eu-de-1`  | `eu-de-1d`   |
| `lh-a-eu-de-2`  | `a`       | `eu-de-2`  | `eu-de-2a`   |
| `lh-b-eu-de-2`  | `b`       | `eu-de-2`  | `eu-de-2b`   |
| `lh-a-eu-de-3`  | `a`       | `eu-de-3`  | `eu-de-3a`   |
| `lh-b-eu-de-3`  | `b`       | `eu-de-3`  | `eu-de-3b`   |
| `lh-c-eu-de-3`  | `c`       | `eu-de-3`  | `eu-de-3c`   |
| `lh-b-qa-de-1`  | `b`       | `qa-de-1`  | `qa-de-1b`   |

So **`lh-b-qa-de-1` is supposed to run its control plane in
`qa-de-1b`**. The name is the intent.

This is not a coincidence — it's an operational convention picked
so downstream tooling (and, in our workaround plan, a mutating
admission policy or webhook) can parse the AZ out of the name
without having to look it up elsewhere.

### 7.2 One Lighthouse per AZ per region

Cross-landscape evidence (from `u8s kubectl get shoot -A`):

```
Region eu-de-1  →  lh-a-eu-de-1, lh-b-eu-de-1, lh-d-eu-de-1        (3 Lighthouses, 3 AZs)
Region eu-de-2  →  lh-a-eu-de-2, lh-b-eu-de-2                       (2 Lighthouses, 2 AZs)
Region eu-de-3  →  lh-a-eu-de-3, lh-b-eu-de-3, lh-c-eu-de-3        (3 Lighthouses, 3 AZs)
Region qa-de-1  →  lh-b-qa-de-1                                     (1 Lighthouse — QA minimal footprint)
```

The pattern is **one Lighthouse shoot per AZ that has KVM compute
in that region**. Any two Lighthouses in the same region are
otherwise identical shoots; the only thing that distinguishes them
is which AZ they serve. That distinction has to be reflected in
where their control plane runs.

### 7.3 Why the Lighthouse has to be pinned to the same AZ it serves

Lighthouse is workerless *in Gardener's data model*, but it has
real clients. Those clients are the **KVM hypervisor nodes of
other shoots in the same AZ**. Specifically, for `qa-de-1`:

```
AZ qa-de-1b
────────────────────────────────────────────────────────────

KVM shoot cc-b0-qa-de-1
├── kube-apiserver  (own CP, should be in 1b — see §1)
└── workers = KVM hypervisors, all in qa-de-1b
     │
     │  in addition to talking to their OWN apiserver, they also
     │  register with and continuously watch Lighthouse's apiserver
     ▼
Lighthouse shoot lh-b-qa-de-1
├── kube-apiserver  (should be in 1b — subject of this doc)
├── etcd
└── workers = none
```

Lighthouse's kube-apiserver serves as a **shared coordinator API
for all KVM compute in one AZ**. Its role is roughly analogous to
a per-AZ "index cluster" that aggregates state across the many KVM
shoots in that AZ. Hypervisors publish and subscribe to CRDs on
Lighthouse; higher-level scheduling and compute-orchestration
tooling reads from it.

The consequence: **the entire traffic pattern between a KVM
hypervisor and its Lighthouse is a hot path**. Every hypervisor in
AZ `1b` calls `lh-b-qa-de-1`'s apiserver constantly. If that
apiserver lands in `1a` (the current random-selection risk), then:

1. **Cross-AZ latency on every operation.** Every watch event,
   list, patch, and heartbeat traverses `1b → 1a → 1b`.
2. **Cross-AZ bandwidth cost.** Scales linearly with hypervisor
   count and their update rate.
3. **Blast-radius escalation.** If AZ `1a` goes down, the
   Lighthouse for AZ `1b` goes down too. Every KVM shoot in `1b`
   loses its coordinator, even though `1b` itself is perfectly
   healthy. Directly breaks the AZ-isolation guarantee that
   motivated the "one Lighthouse per AZ" topology in the first
   place.

Reason 3 is the deciding one. The whole reason there is a
Lighthouse *per AZ* (rather than one HA Lighthouse spanning zones
— option (a) from Tim Usner's Slack proposal) is so that AZ
outages don't ripple across AZs. That property is *silently*
broken today whenever a Lighthouse CP lands in the wrong AZ.

### 7.4 Why `zoneSelection` cannot fix Lighthouse

Gardener's `zoneSelection` algorithm needs a set of "worker
zones" to intersect against the seed's zones. Lighthouse's
`spec.provider.workers` is `[]`. So under both modes:

| Mode      | Intersection | Result                                                                                       |
| --------- | ------------ | -------------------------------------------------------------------------------------------- |
| unset     | n/a          | Random pick from seed zones (same as today). **Current state.**                              |
| `Prefer`  | `∅ ∩ seed = ∅` | Falls back to random. **Same as today — no regression, no fix.**                            |
| `Enforce` | `∅ ∩ seed = ∅` | Refuses to schedule. **New failure mode**: `lh-b-qa-de-1` would go into ReconcileError.    |

That is why `Enforce` is not safe today, and why the Lighthouse
problem needs a different mechanism entirely — one that can
consume the shoot name (or an explicit field) to know the
intended AZ.

### 7.5 The path forward for Lighthouse

Documented in detail in
[`gardener-shoot-cp-az-placement.md`](./gardener-shoot-cp-az-placement.md)
§8.2 and summarized here:

- **Short-term:** downstream mutating admission (webhook or CEL
  policy) on the seed that watches for `Namespace` creations
  named `shoot--<project>--lh-<az>-<region>-…` and writes the
  correct value into the `high-availability-config.resources
  .gardener.cloud/zones` annotation on the namespace. On
  `mgmt-qa-de-1` today the CEL `MutatingAdmissionPolicy` API is
  not available (Kubernetes 1.33 without the feature gate), so a
  classic `MutatingWebhookConfiguration` + small webhook
  Deployment is the right shape.
- **Long-term:** upstream Gardener adds a
  `Shoot.spec.controlPlane.zone` field (in design; Slack thread
  §2.1 step 10 of the AZ-placement doc). Once merged, Lighthouse
  gets a first-class way to declare its target AZ and no
  downstream workaround is needed.

### 7.6 Consequence for the first PR

Because `Prefer` mode leaves Lighthouse in its current random
state (no regression, no fix), the first PR does **not** address
Lighthouse. Lighthouse is a separate workstream. If we chose
`Enforce`, we would break Lighthouse scheduling — a strong
additional reason for the recommendation in §6 to start with
`Prefer`.

---

## 8. Concrete follow-up actions

| # | Action                                                                                              | Owner                          | Blocks?                                                                              |
| - | --------------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------ |
| 1 | Ship the `zoneSelection: Prefer` PR for qa-de-1 (see §8 of the AZ-placement doc for the mechanics). | this task                      | Nothing — safe to land now.                                                          |
| 2 | Right after #1: patch `cc-b1-qa-de-1`'s CP namespace annotation to `qa-de-1b` and roll the CP pods to move its live-misplaced apiserver back to AZ `1b`. | seed operator                  | Nothing — one-shot maintenance.                                                      |
| 3 | Wait for AZ-D readiness: seed nodes re-added in `qa-de-1d`, network stability confirmed, `qa-de-1d` re-added to `Seed.spec.provider.zones`. | Compute / Metal / Seed team    | Blocks the flip to `Enforce`. Tracked separately per Dmitri's suggestion.            |
| 4 | Migrate `cc-d0-qa-de-1`'s PVs to AZ-D as part of the AZ-D re-deploy work. | Compute team                   | Blocks the flip.                                                                     |
| 5 | Once #3 + #4 done: open follow-up PR to flip qa-de-1 from `Prefer` → `Enforce`. Start rolling to other landscapes at the same time. | this task's successor          | Nothing.                                                                             |
| 6 | Separately: design the Lighthouse workaround (mutating webhook on the seed). See §7.5 and AZ-placement doc §8.2. | this task's successor          | Nothing — parallel work.                                                             |
| 7 | Open a separate discussion thread on "flip qa-de-1 to Enforce" once #3/#4 have concrete timing, so it doesn't derail the initial rollout (Dmitri's suggestion in §5.4). | this task's successor          | Nothing — coordination step.                                                         |

---

## 9. Quick "run these to reproduce the finding" reference

Paste-friendly for the next engineer who wants to sanity-check:

```bash
# 1. What zones does each qa-de-1 metal shoot want its workers in?
u8s --context g-qa-de-1 kubectl -n garden-compute get shoots -o json \
  | jq -r '.items[]
           | .metadata.name as $n
           | .spec.provider.workers[]?
           | "\($n)\t\(.name)\tzones=\(.zones)"'

# 2. What zones does the mgmt seed advertise?
u8s --context g-qa-de-1 kubectl get seed mgmt-qa-de-1 \
  -o jsonpath='{.spec.provider.zones}'; echo

# 3. What zones do the mgmt seed's actual nodes live in?
u8s --context mgmt-qa-de-1 kubectl get nodes \
  -L topology.kubernetes.io/zone --no-headers \
  | awk '{print $6}' | sort | uniq -c

# 4. What zoneSelection mode is currently set on the seed? (empty = default random)
u8s --context g-qa-de-1 kubectl get seed mgmt-qa-de-1 \
  -o jsonpath='{.spec.settings.zoneSelection}'; echo
```

Expected outputs at time of writing (2026-06-30):

```
1) cc-b*-qa-de-1  → zones=["qa-de-1b"]   (many pool rows)
   cc-d0-qa-de-1  → zones=["qa-de-1d"]   ← THE MISMATCH
2) ["qa-de-1a","qa-de-1b"]
3) 3 qa-de-1a
   3 qa-de-1b
4) (empty)                                ← default random
```

If any of these change, re-evaluate the decision in §5.
