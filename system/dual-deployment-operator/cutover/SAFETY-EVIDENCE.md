# Safety evidence contract

Do not fill proof fields with generic placeholders or copy fixture evidence into
a real window. These are trusted, recent human attestations with independently
reviewed, hash-bound artifacts. Keep them in private persistent storage.

## Identity and preparation

Every record has `identity` equal to the exact run identity, `dryRun: false`, a
nonempty `verifiedBy` and integer Unix-seconds `verifiedAtEpoch`. Verification must
be within the last 24 hours and not in the future. The identity keys are:

`operator`, `cluster`, `targetContext`, `seedContext`, `namespace`, `release`,
`ddoCR`, `deployment`, `budgetSeconds`, `profileContract`.

All identity values are strings, including `budgetSeconds`. `profileContract`
contains the exact profile preservation/freeze/selector settings; do not reconstruct
it by hand. Generate the candidate identity without executing `main`, making any
release/CR overrides exactly those you will supply to the real invocation:

```bash
# Run in the cutover directory. This sources functions; it does not run cluster calls.
bash -c 'source ./cutover-ddo.sh
OPERATOR=ipam-capi-remote; CLUSTER=m-qa-de-200
TARGET_CTX=m-qa-de-200; SEED_CTX=a-qa-de-200
NAMESPACE=shoot--cp--m-qa-de-200; OUTAGE_BUDGET_MIN=20
load_profile >&2
run_identity' > /private/path/candidate-identity.json
```

Review every coordinate and profile before embedding this object. The real run
publishes its own identity and requires equality; do not initialize a real active
run solely to obtain an identity. An incomplete active capture deliberately cannot
be overwritten/resumed.

## Freeze record (`--freeze-evidence`)

Common header above, plus nonempty strings:

* `reconciler`: actual reconciler/declarative source and coordinates.
* `originalState`: original settings needed for restoration.
* `freezeProof`: observed proof the legacy desired state is disabled without
  destroying the deployed release. Scaling one Deployment alone is not proof.
* `restoreOnSuccess`, `restoreOnRollback`, `restoreOnInterruption`: precise,
  reviewed procedures that avoid reintroducing legacy/DDO dual ownership.

Required booleans: `legacyDesiredStateDisabled: true`,
`restorationAvoidsDualOwnership: true`.

During resume only `verifiedBy`, `verifiedAtEpoch` and `freezeProof` may be refreshed.
Original state and restoration contract must match the sealed original record.

## Readiness record (`--readiness-evidence`)

Common header, plus nonempty strings:

* `installedDDO`, `installedAdmin`: actual installed controller/admin identities.
* `sourceResolution`: immutable resolution of the reviewed replacement source.
* `expectedOwnerValue`: exact expected DDO ownership label value.
* `releasePublicationProof`: proof the installed delivery path can obtain the source.
* `legacyArchiveProvenance`: proof the archive bytes reproduce the installed legacy
  release, beyond a matching chart name/version.
* `legacyArchiveSha256`: lowercase 64-hex digest of that exact `.tgz`.

Required booleans: `sourcePublished: true`, `actualRendersReviewed: true`,
`legacyArchiveMatchesInstalledRelease: true`.

Each of `seedRender`, `shootRender`, `ddoCRManifest` is an object with `file` and
`sha256`. Store the file relative to the readiness record and hash its exact bytes:

```json
{"file":"seed-render.json","sha256":"<actual lowercase SHA-256>"}
```

Artifacts must be valid, nonempty Kubernetes JSON Lists. Seed/shoot artifacts are
the actual reviewed delivery manifests, after environment-specific configuration
and transformations. `ddoCRManifest` contains the exact intended CR, with its
name/namespace and source. The tool copies these artifacts into sealed evidence;
resume may refresh only readiness verifier/timestamp, not the source contract.

### Additional IPAM readiness

Required true booleans: `ddoGitFetchVerified`, `ddoHTTPFetchVerified`,
`adminKustomizeSourceVerified`, `failPolicyPreserved`, `injectorAndAdmissionRehearsed`.

Required nonempty strings: `immutableGitCommit` (40 lowercase hex), `gitFetchProof`,
`httpFetchProof`, `adminRenderProof`, `webhookRehearsalProof`.

The reviewed List must contain exactly one DDO CR. Its Kustomize URL `?ref=` must
equal `immutableGitCommit` and both overlay paths must be supplied. Git and HTTP
proof must establish the installed safe-fetch implementation, including cold-cache
success, warm-cache operation without egress, unavailable uncached source failure
and repeatability. Admin proof must cover real `source.kustomize` CR rendering and
publication/installation. A mutable branch/tag pin or local CLI success is insufficient.

## Acceptance record (`--acceptance-evidence`)

Common header plus nonempty `functionalChecks`, `doNoHarmChecks`: concrete probe
results, observation timestamps/artifacts and impact checks. Health/UID validation
performed by the script is necessary but does not replace these functional checks.

IPAM also requires true `failPolicyPreserved`, `injectorLabelsVerified`,
`webhookURLsVerified`, `caAndCertificatesVerified`, `endpointReachabilityVerified`,
`admissionAllowedAndDeniedVerified`. Check both webhook configurations and actual
positive/negative admission behavior; do not bypass failure policy to obtain a pass.

Acceptance is publish-once in the active state; a mismatched subsequent record
blocks. Validate records/artifacts carefully before invoking verify.

## What evidence does not prove

No schema can prove a human's claims true. This tool validates identity, age,
required acknowledgments, hashes and selected manifest/live invariants; it cannot
certify deployment capabilities or freeze durability from prose. Independent review,
secure external backups and a controlled window are still required. Never commit
captured credentials/Secrets, fabricate success fields, or overwrite the original
baseline to accommodate changed/deleted objects.
