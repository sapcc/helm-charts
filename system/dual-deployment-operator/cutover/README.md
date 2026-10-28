# DDO Cutover Toolkit

Tooling to migrate a Gardener extension operator from the legacy
ManagedResource + Helm-release model to **dual-deployment-operator (DDO)**
management, one chart at a time, safely.

The toolkit has **two layers**:

| Layer | Script | Role | Mutates? |
| --- | --- | --- | --- |
| 1 | `scan-ddo-migration.sh` | Fleet scanner — walks the known remote charts on a cluster, reports the **next** chart to migrate | **No** (read-only) |
| 2 | `cutover-ddo.sh` | Per-chart cutover engine — runs uninstall → handoff → verify for one chart | Yes (uninstall confirmed; preflight namespace MR patch is not) |

Both layers read the **same per-operator profile files** under `profiles/`, so
"which charts exist and how to identify each" has a single source of truth.

---

## Layer 1 — `scan-ddo-migration.sh` (fleet scanner)

Read-only. Walks every profile under `profiles/` in ascending `ROLLOUT_ORDER`,
classifies each chart's migration state **cluster-authoritatively**, prints a
`chart | state | detail` table, and stops at the first chart that needs action.

```bash
./scan-ddo-migration.sh --cluster m-qa-de-200
```

`--cluster <shoot>` names the **shoot** (e.g. `m-qa-de-200`) and derives
`NAMESPACE=shoot--cp--<shoot>`. The DDO CR and the legacy Helm release both
live on the **seed** cluster, so the scanner **auto-discovers the seed context**
that hosts `shoot--cp--<shoot>` (region-ranked probe; e.g. `m-qa-de-200` →
`a-qa-de-200`). Override discovery by exporting `SEED_CTX` (or `NAMESPACE`)
before invoking; narrow the ranking with `SEED_PREFIXES` (default `a g rt`).
Seed discovery is shared with `cutover-ddo.sh` via `lib/ddo-common.sh`.

### States

| State | Meaning | Scanner action |
| --- | --- | --- |
| `migrated` | DDO CR exists AND `Ready=True` AND the legacy Helm release is **absent** | skip, continue to next |
| `not-migrated` | legacy Helm release **present** AND DDO CR absent | print `next candidate: <release>`, **stop** |
| `attention` | ambiguous: legacy release AND CR both present; OR both absent; OR CR present but `Ready!=True` | print `needs attention: <release> (<why>)`, **stop** |
| `unknown` | any state read **errored** (connectivity / auth / API) | print `needs attention`, **stop**, non-zero exit |

The walk **stops at the first non-`migrated` chart** — it never nominates a
fresh candidate past an `attention`/`unknown` chart, because a mid-cutover or
unreadable cluster is exactly when you must not start another migration. Only
when **every** chart is `migrated` does it scan the whole list and print
`all charts migrated`.

Fail-closed by construction: a read error is classified `unknown` (never
silently `migrated` or `not-migrated`), and a missing/empty profile directory
exits non-zero rather than falsely reporting "all charts migrated".

---

## Layer 2 — `cutover-ddo.sh` (per-chart cutover engine)

Runs the coordinated single-window cutover for **one** chart, selected by
`--operator`. Two phases, run separately (see `MIGRATION-CUTOVER-RUNBOOK.md`
for the full procedure):

```bash
# Phase 1: preflight gates + confirmed uninstall + teardown barrier, then pause.
./cutover-ddo.sh --operator boot --phase uninstall --cluster m-qa-de-200

# ... merge the kube-secrets DDO-CR PR, wait for reconcile ...

# Phase 2: automated presence/CRD UID checks, then manual acceptance per runbook.
./cutover-ddo.sh --operator boot --phase verify --cluster m-qa-de-200

# Preview (no cluster mutations; still writes local state files):
./cutover-ddo.sh --operator boot --phase uninstall --cluster m-qa-de-200 --dry-run
```

`--cluster` names the **shoot**. The target/shoot context and the seed
control-plane namespace are derived from it (`--target-context=<shoot>`,
`--namespace=shoot--cp--<shoot>`) and the seed context is auto-discovered;
override any of them with the optional flags below.

### Flags

| Flag | Required | Meaning |
| --- | --- | --- |
| `--operator <name>` | yes | Profile to use (`metal`, `boot`) — selects `profiles/<name>-operator-remote.env` |
| `--phase <uninstall\|verify>` | yes | Which phase to run |
| `--cluster <shoot>` | yes | Shoot cluster name (e.g. `m-qa-de-200`) |
| `--target-context <ctx>` | no | kubectl context for the target/shoot cluster (default: `--cluster`) |
| `--namespace <ns>` | no | Seed CP namespace (default: `shoot--cp--<shoot>`) |
| `--seed-context <ctx>` | no | Seed kubectl context (auto-discovered if omitted) |
| `--release <name>` | no | Override the profile's `RELEASE` |
| `--ddo-cr <name>` | no | Override the profile's `DDO_CR` |
| `--deploy <name>` | no | Override the profile's `DEPLOY` |
| `--dry-run` | no | Suppress namespace-MR patch in both phases. **Uninstall:** still capture local state; skip uninstall/barrier, print handoff and exit 20 (**not permission to merge**). **Verify:** normal read checks and exit code (0 on success), no uninstall snapshots or handoff |
| `--outage-budget <min>` | no | Budget polled by teardown barrier and checked only at verify entry (default 20); not enforced through verify-success |
| `--skip-prereq-check` | no | Skip the DDO-prereq gate — **pre-window rehearsals only** |
| `--help` | no | Usage |

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Automated phase checks completed; manual acceptance still required |
| `2` | Abort — usage error, gate blocked, or confirmation mismatch; MR patch or uninstall may already have happened; inspect execution progress/live state |
| `20` | Handoff printed — **not a failure**; after real uninstall + barrier, merge the CR PR and run verify; **dry-run also exits 20, NOT permission to merge** |
| `30` | Outage budget blown — invoke the rollback plan the script printed |

Primary `obj_state` / Helm state classification is fail-closed: read errors
are not absence (initial rollback CR/Deployment errors select S0; scanner
`obj_state`/`helm_state` errors select unknown). **Not all reads fail closed**:
freeze reads matching missing-resource-type / `could not find` are skipped;
baseline and rollback-material capture failures are ignored; a secondary
namespace timestamp read failure becomes empty; secondary rollback
readiness/ownership read errors can fall through to S2. See the runbook for
required manual checks before following a printed rollback plan.

Preflight can patch the namespace MR to `keepObjects:true` **before uninstall
confirmation**; verify re-runs preflight and can patch it too. The prerequisite
gate only requires Deployment LIST success (even empty), DDO CRD existence,
and target read authorization; chart-render failures only warn. **Before
uninstall, manually confirm target identity/expected CRDs, DDO controller
availability with ready replicas, DDO CRD Established, and clean chart renders
for both seed/shoot modes.** Verify prints CR conditions, only warns on missing
ownership, and checks sample existence, not health or UID. Follow the runbook's
manual ownership/health, CR Ready and sample UID/Ready/deletionTimestamp checks.

**Preserve the state directory** (`${TMPDIR:-/tmp}/ddo-cutover-<operator>-<cluster>`)
between phases, including `uninstall-epoch` and baseline/rollback files; verify
skips its budget check if the epoch is missing. Nothing monitors the handoff
pause or the remainder of verification: **operator must monitor the clock**.

---

## Profiles — the shared source of truth

Each participating chart has one file: `profiles/<operator>-operator-remote.env`.
Both layers read it. Fields:

| Field | Used by | Meaning |
| --- | --- | --- |
| `RELEASE` | both | Legacy Helm release name on the seed |
| `DDO_CR` | both | `DualDeploymentOperator` CR name |
| `LEGACY_CHART_DIR` | informational; currently unused | Sourced by both layers, but neither uses it to locate a chart or perform rollback; printed S1 install uses `OPERAND_CHART_DIR`, without a version pin |
| `ROLLOUT_ORDER` | scanner | Integer; scanner walks profiles ascending |
| `DEPLOY` | cutover | Controller Deployment name on the seed |
| `CONTROLLER_POD_SELECTOR` | cutover | Pod label selector for the controller (teardown barrier) |
| `CRD_GROUPS` | cutover | CRD API group(s) — checked for `keepObjects:true` + UID preservation |
| `NAMESPACE_CASCADE_GATE` | cutover | `on <mr-name> <namespace>` or `off` (see below) |
| `FREEZE_KINDS_CLUSTER` | cutover | Cluster-scoped kinds checked for `deletionTimestamp` (may be empty) |
| `FREEZE_KINDS_NS` | cutover | Namespaced kinds checked for `deletionTimestamp` (`-A`) |
| `FREEZE_SERVER_STATES` | cutover | `1` to also run the hardware state-machine checks; `0` to skip |
| `SERVER_STABLE_STATES_REGEX` | cutover | (when `FREEZE_SERVER_STATES=1`) stable `Server.status.state` values |
| `OPERAND_CHART_DIR` | cutover | Operand chart path for non-blocking template checks and printed S1 install; establish correct legacy chart/exact version manually for recovery |
| `BASELINE_SNAPSHOT_KINDS_CLUSTER` / `_NS` | cutover | Kinds dumped pre-uninstall for diffing |
| `VERIFY_SAMPLE` | cutover | Foreign-shoot object checked for existence only — `<kind> <name>` or `<kind> -n <ns> <name>`; UID/Ready/not-Terminating are manual checks |
| `OWNED_BY_LABEL` | cutover | The label DDO stamps on managed objects |

### `NAMESPACE_CASCADE_GATE` — on vs off

Some operators own a Namespace via a ManagedResource (metal owns
`metal-servers`). For those, the gate is **on**: the engine patches the
namespace MR to `keepObjects:true` before confirmation (also during verify).
A missing MR only warns/skips. The barrier checks namespace existence and
deletionTimestamp, but a secondary timestamp read error becomes empty:
**manually confirm protection and survival**. Operators that own **no** namespace (boot) set
it **off**, and the engine never queries a namespace MR for them.

### Onboarding a new operator

1. Copy an existing `profiles/<op>-operator-remote.env` and set every field for
   the new operator.
2. Give it a distinct `ROLLOUT_ORDER` (determines scanner walk position).
3. Set `NAMESPACE_CASCADE_GATE` / `FREEZE_SERVER_STATES` to match whether the
   operator owns a namespace / has a hardware state machine.
4. Point `OPERAND_CHART_DIR` at the operator's `-ddo` operand chart.
5. Add a case to the tests (see below) and run them.

No scanner/engine code changes are needed to add an operator — only a profile.

---

## Tests

```bash
bash tests/scan_test.sh              # Layer 1 classifier (fake u8s fixtures)
bash tests/cutover_profile_test.sh   # Layer 2 profile selection + gate routing
```

Both use a fake `u8s` on `PATH` with scripted fixtures — no live cluster is
needed to run them.
