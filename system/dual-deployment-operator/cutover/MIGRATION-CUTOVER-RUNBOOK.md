# DDO Migration Cutover Runbook

> **Scope:** Replacing a legacy `<operator>-remote` Helm release with
> dual-deployment-operator (DDO)-managed deployment on a single cluster, using
> `cutover-ddo.sh --operator <name>`.
>
> **Audience:** operator running a planned maintenance window. `helm uninstall`
> is gated behind an exact-token confirmation, but preflight can patch the
> namespace ManagedResource to `keepObjects:true` **before confirmation**.
> Verify re-runs that preflight and can also patch it. Applying the DDO CR happens **outside** this
> script (merge the kube-secrets PR + reconcile).
>
> **Profile-driven:** the per-operator differences (namespace ownership, freeze
> predicate, CRDs, do-no-harm sample) live in
> `profiles/<operator>-operator-remote.env`. This runbook describes the shared
> procedure; the **boot-operator specifics** are called out in §6.

---

## 0. TL;DR — the one thing to get right

You cannot safely do either half alone:

| Naive action | Why it fails |
| --- | --- |
| **Uninstall the legacy release only** | The running controller disappears while CR finalizers are live → reconcile deadlock until the DDO CR lands. |
| **Apply the DDO CR while the old release still lives** | DDO and the old release render the **same controller Deployment** with **different immutable `spec.selector`** → SSA cannot mutate it → DDO goes `Degraded`, two owners churn. |

**The correct path is a coordinated cutover in one window:**

```
uninstall <release>  →  merge DDO-CR PR + reconcile  →  DDO renders & applies  →  verify
```

The gap between uninstall and CR-reconcile is a **single-controller outage**
that the operator must keep within the budget (§4). CRDs + CR data are protected by `keepObjects:true`
and finalizers only *pause* (they do not destroy anything) while no controller
runs — provided nobody deletes a finalized CR during the window (**the freeze**).

---

## 1. Phases & exit codes

`cutover-ddo.sh` runs in two phases:

```bash
# Phase 1 — preflight gates + confirmed uninstall + teardown barrier, then pause (exit 20).
./cutover-ddo.sh --operator <name> --phase uninstall --cluster <shoot>

# ... merge the kube-secrets DDO-CR PR for this cluster, wait for reconcile ...

# Phase 2 — automated presence/CRD UID checks, then manual acceptance (see §6).
./cutover-ddo.sh --operator <name> --phase verify --cluster <shoot>
```

> `--cluster <shoot>` is the only cluster coordinate you need: the target/shoot
> context defaults to `<shoot>`, the seed namespace to `shoot--cp--<shoot>`, and
> the seed context is auto-discovered. Override with `--target-context`,
> `--namespace`, or `--seed-context` when a name diverges.

| Exit | Meaning | What to do |
| --- | --- | --- |
| `0` | automated phase checks completed | finish the manual acceptance checks before declaring success |
| `2` | aborted by a gate / confirmation / usage error | inspect output and live state to determine how far execution got; the MR patch or uninstall may already have happened |
| `20` | handoff printed — **not an error**; also returned by dry-run | only after a real uninstall + teardown barrier, merge the CR PR, let it reconcile, then run `--phase verify`; **dry-run exit 20 is not permission to merge** |
| `30` | outage budget blown | invoke the rollback plan the script printed (§5) |

Always preview first: add `--dry-run` to the uninstall phase. This suppresses
cluster mutations, but still writes local snapshots/rollback files and prints
the handoff; it skips uninstall and the teardown barrier.

---

## 2. Preflight gates and manual prerequisites

Both phases run preflight. With the namespace gate `on`, it can patch the MR
before the uninstall confirmation; neither phase is strictly read-only.
Exit `2` does **not** mean nothing changed (including after uninstall if the
barrier detects namespace loss). Primary `obj_state` object reads distinguish
server-side NotFound from errors, but the exceptions below matter.

1. **Target connectivity / CRD probes** — attempts to read the target's
   `default` namespace **once**, without a cold-login retry or cluster-identity
   comparison. A successful **empty** label-filtered CRD list passes the CRD
   probe. **Operator must manually confirm the target identity and that all
   expected CRDs are present** before uninstall.
2. **CRD ManagedResources `keepObjects:true`** — every `mr-crd-*` for this
   release must have `keepObjects:true`, or uninstall would cascade-delete the
   CRDs and all CRs. A violation aborts.
3. **Namespace-cascade gate** *(only if the profile's `NAMESPACE_CASCADE_GATE`
   is `on`)* — patches the owned namespace's MR to `keepObjects:true`
   (idempotent, **before uninstall confirmation**, also during verify). A missing
   MR only warns and is skipped: **manually confirm the namespace is protected**.
   **Skipped entirely when the gate is `off`** (operator owns no namespace).
4. **Freeze gate** — checks the configured kinds:
   - **Deletion checks:** inspects `deletionTimestamp` on the profile's
     `FREEZE_KINDS_CLUSTER` / `FREEZE_KINDS_NS`. Deletions are split into
     **fresh** (< `FRESH_DELETE_MIN`, default 48h → **block**, a delete is in
     flight) vs **stale** (older → warn + continue, pre-existing debt the
     cutover inherits unchanged). An **unparseable** timestamp is treated as
      fresh → block. Failed reads matching missing-resource-type or
      `could not find` are warned and **skipped**; other list errors abort.
      **Operator must manually resolve skipped reads and confirm the freeze.**
   - **Hardware state machine** *(only if `FREEZE_SERVER_STATES=1`)*:
      checks `Server.status.state` against `SERVER_STABLE_STATES_REGEX` only
      where state exists; Servers with missing state are **skipped**.
      BIOSSettings/BIOSVersion block only on `observedGeneration < generation`
      where **both fields exist and the object is not deleting**. No BIOS
      terminal state is checked. **Operator must manually confirm Server/BIOS
      terminal states and investigate missing status fields.** Operators with
      `FREEZE_SERVER_STATES=0` skip these hardware checks.
5. **DDO prerequisites** *(unless `--skip-prereq-check`)* — requires a successful
   seed-wide Deployment LIST with the DDO instance selector (**even an empty
   list passes**, no availability or replica check), existence of the
   `DualDeploymentOperator` CRD (**not** Established), and successful target
   `auth can-i get crd`. Missing shoot-access Secret warns; read errors block.
   Local `helm template` is attempted for `mode=seed` and `mode=shoot` if the
   operand chart directory exists; render failures are **non-blocking warnings**,
   and a missing directory skips rendering.

> **Operator must manually verify before uninstall:** the DDO controller is
> `Available=True` with ready replicas, the DualDeploymentOperator CRD is
> `Established=True`, and the operand chart renders cleanly for **both**
> `mode=seed` and `mode=shoot`. A passed prerequisite gate does not prove these.

> `--skip-prereq-check` is for **pre-window rehearsals only** — never a real window.

### The freeze is load-bearing

During the uninstall→CR-reconcile gap, a finalized CR that receives a
`deletionTimestamp` with **no controller running** hangs in `Terminating`
forever. **Do not delete, drain, or GC any of this operator's CRs during the
window, and never strip a finalizer by hand to "unstick" one.**

---

## 3. Uninstall phase (§1 Phase 1 in detail)

1. Preflight (§2) + attempted baseline snapshots (the profile's
   `BASELINE_SNAPSHOT_KINDS_*` for later diffing, CRD UIDs, live finalizers).
   Capture failures are ignored. **Manually validate the files are complete and
   record the sample's UID, Ready condition and deletionTimestamp before uninstall.**
2. Read the old release state, fail-closed: a helm/API **error** is never read
   as "already removed".
3. Attempt rollback capture (`helm get manifest` / `helm get values` / `helm get all`).
   Failures are ignored; **manually validate usable rollback material and record
   the correct legacy chart and exact version before confirming uninstall**.
4. **DESTRUCTIVE** — exact-token confirmation, then `helm uninstall`. Stamps the
   uninstall time for the outage-budget clock. (`--dry-run` describes only.)
5. **Teardown barrier** (§4) — wait for the old release to fully drain.
6. Print the handoff instructions and exit `20` (also happens in dry-run).

---

## 4. Teardown barrier

`helm uninstall` returns before the Gardener Resource Manager finishes
finalizing the release's ManagedResources. Applying the DDO CR during that lag
races GRM (DDO adopts an object GRM then deletes). The barrier blocks (bounded
by the outage budget) until all of:

- **Every ManagedResource owned by THIS release is gone**, where ownership is
  determined **strictly by the `meta.helm.sh/release-name` annotation equal to
  the release** — **never by an `mr-*` name prefix.** The seed CP namespace is
  shared by ~9 releases whose MRs are also named `mr-*`; a prefix match would
  either wait forever on foreign MRs or wrongly delete them. `mr-crd-*` for this
  release are intentionally retained (keepObjects). A failed **list** of MRs
  counts as "not yet gone" (keep waiting), never "gone".
- **No controller Pods** matching `CONTROLLER_POD_SELECTOR` remain on the seed.
- *(Namespace-cascade gate `on` only)* the owned namespace on the target exists
  and checks for a `deletionTimestamp`. A failure of this secondary timestamp
  read is treated as an **empty value**, so **manually verify the namespace
  exists and is not Terminating**. If it is gone or a timestamp is detected, that is a
  hard stop (unrecoverable by waiting) — the script prints the rollback plan and
  aborts. **Skipped when the gate is `off`.**

On budget timeout the barrier prints the rollback plan and aborts.

### Budget enforcement and state preservation

The barrier polls the budget; verify checks it **only at entry**, using elapsed
whole minutes, and **skips the check entirely if `uninstall-epoch` is missing**.
There is no monitoring during the handoff pause or through verify completion.
**Preserve `${TMPDIR:-/tmp}/ddo-cutover-<operator>-<cluster>` between phases**
(same TMPDIR/operator/cluster), including `uninstall-epoch`, CRD UID baselines
and rollback files. The barrier falls back to its start time if the epoch cannot
be read. **Operator must monitor the clock during handoff and verification**
and act on budget expiry; do not rely on an eventual exit `0` to enforce it.

---

## 5. Rollback — four states (`print_rollback_plan`)

The engine **prints** a procedure; it does not execute rollback. Its initial
`obj_state` reads of the CR/Deployment are fail-closed: errors select S0, not
absence. The Helm release lookup likewise distinguishes a typed missing release
from an error (the scanner uses `helm_state`). This is **not** a throughout-script
guarantee: freeze reads can be skipped (§2), baseline/rollback captures can fail
silently (§3), and namespace timestamp reads can become empty (§4).
Also, **secondary readiness/ownership read errors in rollback can fall through
to S2 instead of S0**. Manually establish readable health/ownership before
following a destructive printed plan.

| State | How detected | Rollback shape |
| --- | --- | --- |
| **S0** — UNREADABLE | the DDO CR and/or controller Deployment read **errored** (not a clean NotFound) | **Do nothing automatically.** Restore connectivity, re-run verify; escalate. Never defaults to S1. |
| **S1** — uninstall done, nothing landed | DDO CR **and** Deployment both confirmed absent | printed install uses `OPERAND_CHART_DIR` + rollback values, **no version pin**, not `LEGACY_CHART_DIR`; establish correct legacy chart/exact version and validate captured material before running |
| **S2** — partial / in-progress | remaining readable states not matched by S3 or S1 | detach from DDO **in order**, then reinstall (see below) |
| **S3** — labelled Deployment with ready replicas | Deployment found, `readyReplicas > 0` AND nonempty `owned-by` label value | evaluated **before S2**, regardless of CR presence; **do not roll back the controller** — fix forward; manually confirm correct DDO ownership and full health (`ready == desired > 0`) |

**S2 ordering (namespace-cascade `on`, do NOT reorder):** scale the DDO
controller to 0 (wait for zero pods — a failed pod-list read does **not** count
as zero) → strip the `owned-by` label from the live namespace on the target and
confirm it's gone → delete the DDO CR and gate on **accepted deletion**
(nonempty `deletionTimestamp`, not completion yet) → restart the DDO controller
so its finalizer runs the deletion (skipping the now-unlabelled namespace) →
confirm **completed deletion** (CR returns server-side NotFound), **controller
Deployment gone**, and namespace survived → manually verify the foreign-shoot
sample is intact → reinstall the correct legacy chart/version with validated
rollback values. A failed read is not proof of absence.

When the gate is **off**, the printed S2 plan says to delete the CR and wait for
**deletion to complete (NotFound)** before reinstall; merely accepted deletion
is insufficient. It omits an explicit Deployment-gone step in this branch:
**operator must manually confirm both CR and controller Deployment are gone
before reinstalling**, and verify the sample remains intact.

---

## 6. boot-operator specifics

boot-operator is the simplest profile — the gates adapt via
`profiles/boot-operator-remote.env`:

- **No namespace of its own.** `NAMESPACE_CASCADE_GATE=off` → the namespace
  keepObjects patch and the teardown barrier's namespace-survival check are
  **skipped entirely**. The script never queries a namespace MR for boot. (S2
  rollback uses the collapsed, no-namespace path.)
- **Minimal freeze gate.** `FREEZE_SERVER_STATES=0` and no cluster-scoped kinds;
  the freeze is just `deletionTimestamp` checks on
  `httpbootconfigs.boot.ironcore.dev` and `ipxebootconfigs.boot.ironcore.dev`.
  No Server / BIOS / BMC hardware state machine.
- **CRDs:** `boot.ironcore.dev` (HTTPBootConfig, IPXEBootConfig) — preflight checks
  matching CRD MRs for `keepObjects:true`. Verify compares UIDs only for entries
  in baseline files; missing files warn and skip, empty files check nothing.
  **Manually ensure the baseline includes every expected CRD and compare UIDs.**
- **Manual "do no harm" acceptance.** A foreign shoot (`mig-test-metal`) owns an
  IPXEBootConfig in the shared `metal-servers` namespace. It **must** remain
  `Ready`, same UID, **not** Terminating across the whole cutover. The profile's
  `VERIFY_SAMPLE` points verify at it, but the script **only checks existence**,
  not UID, Ready or deletionTimestamp.

  > **Operator action before the window:** confirm the profile's `VERIFY_SAMPLE`
  > object name matches the *actual* live IPXEBootConfig name on the target
  > (list `ipxebootconfigs -n metal-servers` and set the exact name) — the
  > shipped value is a placeholder and the real resource name is
  > cluster-specific.

### Acceptance checks — required for either operator

The script automatically requires the DDO CR, controller Deployment and
configured sample to exist, compares recorded CRD UID entries, prints CR
conditions (without asserting Ready), and warns on a missing Deployment
`owned-by` label (without asserting ownership or health).

**Before declaring success, the operator must manually:**

1. Compare the sample's UID with the pre-uninstall capture, confirm its
   `Ready=True` condition and **empty deletionTimestamp**, and investigate any
   change against the baseline. Recheck these through the window, not just at exit.
2. Confirm the controller Deployment is owned by the intended DDO CR and healthy:
   `Available=True` and `readyReplicas == spec.replicas > 0`.
3. Confirm the DDO CR has `Ready=True`, review conditions/logs, and confirm all
   expected CRD UIDs are preserved using complete baseline records.

Exit `0` alone proves neither adoption nor full do-no-harm.

### metal vs boot at a glance

| Aspect | metal | boot |
| --- | --- | --- |
| Owns a namespace | yes (`metal-servers`) → cascade gate **on** | no → cascade gate **off** |
| Hardware state machine | yes (`FREEZE_SERVER_STATES=1`) | no (`FREEZE_SERVER_STATES=0`) |
| Freeze kinds | servers/bmcs/biossettings/biosversions (+ns claims/bootconfigs/maintenances) | httpbootconfigs/ipxebootconfigs only |
| CRD group | `metal.ironcore.dev` | `boot.ironcore.dev` |
| Do-no-harm sample | `server node001` | `ipxebootconfig -n metal-servers <mig-test-metal ...>` |

---

## 7. Guardrails recap

- ✅ Matching release CRD MRs are checked for `keepObjects:true`; manually confirm coverage.
- ✅ Namespace MR protection is patched when present and the cascade gate is on;
  manually confirm protection/survival if reads are skipped or fail.
- ✅ Freeze gate blocks fresh/unparseable deletions and the specified hardware
  predicates; manually resolve skipped reads and confirm terminal states.
- ✅ DDO-prereq gate checks list success/CRD existence/authorization;
  manually confirm controller availability, CRD establishment and both chart renders.
- ✅ Teardown barrier keys ownership on the release-name annotation, never a
  name prefix (shared namespace).
- ✅ Budget expiry detected by barrier polling or verify entry → plan + exit 30;
  preserve state and manually monitor handoff/verification time.
- ✅ Primary classification read errors select S0/unknown, not absence;
  secondary rollback readiness/ownership errors can still select S2.
- 🚫 Never apply the DDO CR before uninstalling (immutable-selector collision).
- 🚫 Never delete/strip a finalizer on any of this operator's CRs during the
  window.
- 🚫 Never use `--skip-prereq-check` in a real window.
