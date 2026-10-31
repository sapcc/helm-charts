# DDO cutover toolkit

Planned legacy Helm/ManagedResource → DDO SSA handoff, one release and shoot at a
time. This tool fails closed when preservation, recovery or replacement readiness
cannot be established. **It is not an automatic migration or rollback controller.**

Start with [the runbook](MIGRATION-CUTOVER-RUNBOOK.md) and
[the evidence contract](SAFETY-EVIDENCE.md), not a copied uninstall command.

## Components

* `scan-ddo-migration.sh`: read-only candidate inventory; not execution approval.
* `cutover-ddo.sh`: guarded capture/protection/uninstall/barrier and separate verify.
* `profiles/*.env`: exact release identities and preservation/freeze contracts.
* `lib/ddo-common.sh`: shared cluster discovery and object-state helpers.
* `lib/cutover-safety.sh`, `lib/cutover-evidence.py`: engine-only state, evidence,
  JSON validation and whole-process deadline helpers.
* `tests/`: isolated command fixtures; never evidence of live landscape readiness.

Requires Bash, Python 3 (standard library), jq, and working u8s Helm/kubectl access.
Use `./cutover-ddo.sh --help` for all flags. Quote private artifact paths.

## Required real-run inputs

Explicitly confirm shoot/seed context and CP namespace; provide exact installed
legacy `.tgz`, verified legacy reconciler freeze/restoration evidence and actual
replacement delivery-readiness evidence. Verify additionally needs `--resume`,
the same state root/identity/budget and functional acceptance evidence.

`--state-dir` names a private persistent root. Default:
`${XDG_STATE_HOME:-$HOME/.local/state}/ddo-cutover/<operator>-<cluster>`.
An active run is identity-bound and sealed; resume cannot recapture or replace its
original baseline. A local exclusive lock blocks concurrent use of the same root.
Separate roots do not prevent operators from targeting the same cluster: coordinate
the maintenance window outside the script. Preserve sensitive exports securely.

`--dry-run` creates separate rehearsal evidence, never patches/uninstalls, returns
`0` and never grants activation handoff. It still needs valid capture inputs.
`--skip-prereq-check` is available only for rehearsal.

## Safety guarantees and limits

* Required read/parse/capture failures abort; valid empty Lists are distinguished
  from failure, and required protected inventories cannot silently be empty.
* Installed legacy CRD delivery coverage and baseline UIDs are checked.
* Shared-namespace ownership is release-annotation based, never prefix based.
* Protection requires a verified reconciler freeze and immediate keepObjects readback.
* A durable epoch is written before uninstall; every engine u8s process is bounded
  including authentication. A timeout leaves server-side state uncertain.
* Real handoff waits for legacy teardown and UID preservation; verify requires
  current-generation Ready, exact ownership/healthy Deployment and manual acceptance.
* Recovery prints state-dependent guidance, not destructive commands. Partial
  recovery is blocked until specialist inventory/retention review. DDO finalizers
  can delete adopted data: legacy `keepObjects` is not protection from DDO deletion.

Human proof records are attestations with hash-bound artifacts, not automatic
certification of deployed platform capabilities. Checksums/read-only files protect
against accidental changes, not a malicious local writer. The freeze's lasting
effect and functional acceptance remain the window owner's responsibility. Monitor
the outage externally during the activation gap and any manual recovery.

## Profiles

| `--operator` | Release | Particular preservation boundary |
| --- | --- | --- |
| `metal` | metal-operator-remote | namespace cascade and hardware freeze |
| `boot` | boot-operator-remote | boot CR freeze and landscape sample |
| `argora` | argora-operator-remote | three protected data-CR MRs; DDO recovery retention requires separate proof |
| `ipam-capi-remote` | ipam-capi-remote | two out-of-band pool UIDs on m-qa-de-200; Fail-policy webhook acceptance |

IPAM real execution is blocked until installed DDO safe Git/HTTP fetching and
published/installed admin `source.kustomize` CR rendering are demonstrated. Local
CLI rendering, a draft PR, or a version string alone cannot satisfy this gate.

## Validation

From the repository root:

```bash
for test in system/dual-deployment-operator/cutover/tests/*_test.sh; do
  bash "$test" || exit
done
```

The fixture suite covers routing, discovery, scan classification, profile behavior,
capture failures, evidence immutability, preservation, readiness, recovery and
deadline failures. It does not execute a live cutover.
