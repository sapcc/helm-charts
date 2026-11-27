# DDO Migration Cutover Runbook

## Safety boundary

This is a planned, single-cluster maintenance procedure, not automatic rollback.
Do not remove a working legacy release until its exact recovery artifact, preservation
baseline, actual replacement renders and legacy reconciler freeze are established.
The script never activates the replacement CR or performs rollback itself.

**IPAM remains blocked** until the installed DDO supports safe Git-directory **and
HTTP-file** fetching, and the installed/published admin chart actually renders
`source.kustomize`. A successful local Kustomize build is not installed-platform
acceptance. Draft operand/CR PRs are not evidence that these prerequisites exist.

Deletion of a DDO CR can finalize and delete its owned data CRs and namespaces.
`keepObjects:true` protects against legacy ManagedResource teardown, **not DDO
finalization**. Never delete the DDO CR, strip finalizers, or detach ownership as
a generic recovery step. Once `deletionTimestamp` is set, the object cannot be
resurrected with its original UID. See [Kubernetes finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/).

## 1. Prepare the window

1. Select the correct profile and explicit shoot/seed contexts and CP namespace.
   Metal/boot/argora use their short operator names; IPAM uses `ipam-capi-remote`.
   Confirm the actual cluster identities independently.
2. Obtain the **exact installed legacy chart archive**, including dependencies.
   Check immutable provenance/content, digest, chart name and version against the
   deployed release. Never substitute the `*-ddo` operand chart.
3. Prepare `--freeze-evidence` recording the actual legacy reconciler/declarative
   input, original state, proof that legacy desired state is disabled, and precise
   restoration procedures for success, rollback and interruption. Freeze must not
   itself delete the legacy release. Keep legacy desired state disabled while DDO
   owns the replacement; do not blindly restore the old reconciler after an abort.
4. Prepare `--readiness-evidence`: installed DDO/admin identities and capability
   proof, published/resolved source, exact expected ownership label, reviewed
   recovery archive digest/provenance, and hash-bound actual seed/shoot render
   Lists plus the intended DDO CR List. These are environment-specific outputs
   after the real values/transformations, not chart defaults.
5. Plan functional acceptance, operator availability and an external outage clock.
   No deletions, drains or GC of baseline data are permitted during the window.

The JSON schemas and identity preparation procedure are documented in
[`SAFETY-EVIDENCE.md`](SAFETY-EVIDENCE.md). Evidence is a trusted human gate backed
by machine checks, not certification of assertions made by the operator.

## 2. Rehearse without changing live state

```bash
./cutover-ddo.sh --operator ipam-capi-remote --phase uninstall \
  --cluster m-qa-de-200 --seed-context a-qa-de-200 \
  --legacy-chart-archive /private/path/exact-legacy.tgz \
  --state-dir /private/path/window-state --dry-run
```

Rehearsal requires valid installed-release and baseline capture inputs; it does
not require real freeze/readiness attestations. It never patches or uninstalls,
uses a separate rehearsal directory and returns `0` with a rehearsal-only message.
It **does not authorize CR activation**. `--skip-prereq-check` is rehearsal-only.
Do not use `--resume` or the verify phase with `--dry-run`.

## 3. Confirmed uninstall

```bash
./cutover-ddo.sh --operator ipam-capi-remote --phase uninstall \
  --cluster m-qa-de-200 --seed-context a-qa-de-200 \
  --legacy-chart-archive /private/path/exact-legacy.tgz \
  --freeze-evidence /private/path/freeze.json \
  --readiness-evidence /private/path/readiness.json \
  --state-dir /private/path/window-state
```

The tool checks legacy/DDO state before capture, captures and seals evidence,
validates inventories and health, then runs profile preservation/freeze gates.
Real protection patches require the verified freeze contract; they can occur
**before uninstall confirmation**. An abort does not imply nothing changed.

Required captures/parse failures block. Expected CRDs are decoded from the
installed release's CRD-MR Secret payloads and checked on shoot. Ownership of
ManagedResources is strictly `meta.helm.sh/release-name == RELEASE`, never a name
prefix or namespace-wide match. Required protected MRs must be present and
`keepObjects:true`, read back after patch and immediately before destruction.

After exact-token confirmation, a durable epoch is published **before** Helm
uninstall. All engine u8s calls are whole-process bounded by at most 60 seconds
and the remaining outage budget. A timeout may have partially changed server
state: never automatically retry uninstall.

The teardown barrier waits for this release's non-CRD MRs and controller Pods to
disappear, checks namespace survival where configured, verifies baseline UIDs,
and rejects a reappearing legacy release before printing handoff. API errors or
malformed inventories are not absence. Do not activate DDO before this barrier:
immutable Deployment selector and ownership conflicts can otherwise occur.

## 4. Handoff and verify

After real teardown, exit `20` authorizes the printed handoff only for the exact
reviewed source/CR. Keep the reconciler frozen and monitor the outage clock while
activating the durable DDO configuration externally. The script cannot monitor
the gap while it is not running.

```bash
./cutover-ddo.sh --operator ipam-capi-remote --phase verify \
  --cluster m-qa-de-200 --seed-context a-qa-de-200 \
  --resume --state-dir /private/path/window-state \
  --freeze-evidence /private/path/freeze.json \
  --readiness-evidence /private/path/readiness.json \
  --acceptance-evidence /private/path/acceptance.json
```

Use identical original coordinates, profile, budget and overrides. Verify requires
sealed original evidence and the original epoch; it never captures a new baseline.
The tool requires current-generation Ready on the CR, reviewed source equality,
exact expected Deployment ownership, a non-Terminating healthy Deployment with
positive desired/ready/available/updated replicas, legacy release absence, and
baseline object UID/non-Terminating preservation. It separately requires recorded
manual functional/do-no-harm acceptance, and rechecks the seconds deadline before
success. Logs are diagnostic, not proof of functionality.

### IPAM acceptance

On m-qa-de-200 preserve both `metal-servers` GlobalInClusterIPPools:

| Name | Original UID |
| --- | --- |
| `globalinclusterippool-mgmt-qa-de-200` | `83614ed7-f367-4bd0-acdd-4fbd4de76eec` |
| `test` | `d7d99994-c27d-4116-835b-4d858069b7ea` |

These pools are out-of-band, not automatically DDO-owned. Required baseline
capture rejects either missing/changed UID. Inspect allocations and foreign-workload
behavior as well. Verify both mutating and validating injector labels, URLs,
certificates/CA/SANs, endpoint reachability, and positive/negative admission probes.
**Keep `failurePolicy: Fail` unchanged**; weakening it is not acceptance or recovery.

### Other profiles

Metal protects the `metal-servers` namespace and checks configured hardware states.
Boot has no namespace cascade gate and uses boot CR freeze checks; replace any
sample placeholder with its exact landscape object before preparing evidence.
Argora protects three data-CR MRs for same-UID adoption. Those CRs must also survive
any later DDO recovery; their legacy protection is not a DDO retention guarantee.

## 5. State, interruption and rollback

Default root is `${XDG_STATE_HOME:-$HOME/.local/state}/ddo-cutover/<operator>-<cluster>`;
`--state-dir` specifies that root, not its `active/` child. Keep it private: archived
values/manifests can contain Secrets. Store secure backups outside ephemeral temp
storage. A local PID/hostname lock prevents concurrent use of the same root; it
is not a distributed cluster lock. Never auto-break a stale lock.

`active/` holds immutable identity, sealed baseline/recovery artifacts, publish-once
epoch and acceptance. Rehearsals have separate directories. Checksums detect accidental
alteration, not an adversary able to rewrite both evidence and checksums. Do not delete
or overwrite original evidence after an interruption or successful migration.

An incomplete capture or identity mismatch blocks resume. After proving there was
no destructive action/epoch, archive the failed run before preparing a new one.
An epoch plus a still-present release is partial uninstall: specialist recovery is
required, not another uninstall. Read failures or expired budget likewise require
manual assessment, with the freeze maintained until safe restoration is known.

| State | Recovery boundary |
| --- | --- |
| S0: unreadable/malformed | No destructive procedure; restore observability and escalate. |
| S1 candidate: CR and Deployment absent | Absence is not proof of retention. Validate inventories, UIDs and DDO desired-state disablement; only after specialist approval use the exact captured legacy archive/values with explicit seed context/namespace. |
| S2: partial | **Blocked:** do not delete the DDO CR or detach ownership. Review actual inventories, retention and irreversible deletion risks before any recovery. |
| S3: validated new controller/CR healthy | Fix forward; verify preservation and functional acceptance, rather than destroying a healthy replacement. |

Actual DDO namespace/name/UID/selector/original replicas are captured in
`active/evidence/ddo-controller.json`. The tool prints no automatic stop/detach/restart
sequence. Never blindly restart at one replica or restore legacy desired state beside DDO.
Helm operation timeouts are not guarantees of total recovery duration; keep external
monitoring ([Helm rollback documentation](https://helm.sh/docs/helm/helm_rollback/)).

| Exit | Meaning |
| --- | --- |
| `0` | Rehearsal completed, or real verify health/preservation and recorded acceptance passed; read the phase-specific output. |
| `2` | Gate/error/confirmation abort; inspect state and recorded epoch to determine changes already made. |
| `20` | Real uninstall/barrier complete, manual activation handoff. |
| `30` | Seconds deadline exhausted; manual recovery, never blind deletion/restoration. |

After accepted success, preserve/archive evidence and execute only the recorded
success restoration contract, keeping obsolete legacy desired state disabled.
