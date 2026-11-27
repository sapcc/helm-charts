# How to generate the cutover evidence files (any migration candidate)

This is the **generic** procedure for assembling the operator-supplied evidence the real
(non `--dry-run`) uninstall requires. It applies to **every** migration candidate — disco,
kube-state-metrics, metal-operator, boot-operator, argora, ipam-capi-remote, and any future
operator with a profile under `profiles/`.

The whole run is parameterised by the operator's profile (`profiles/<operator>…env`), so the
procedure never changes — only the inputs do. Fill in the placeholders in **Step 0** once and
every later step is copy-paste.

> **Why this exists.** The real uninstall is gated on trusted, recent human attestations with
> hash-bound artifacts (`lib/cutover-safety.sh` → `require_freeze` / `require_manual_contracts`;
> schema in `lib/cutover-evidence.py` → `contract()`). `--freeze-evidence` + `--readiness-evidence`
> are required up front; `--acceptance-evidence` is supplied later at the **verify** phase.
> `--dry-run` skips all of it (rehearsal only — lands in `rehearsals/`, never touches the cluster).
> Read `SAFETY-EVIDENCE.md` for the field-by-field contract and `MIGRATION-CUTOVER-RUNBOOK.md`
> for the end-to-end outage choreography.

---

## Step 0 — set the coordinates (the only per-operator inputs)

```bash
cd system/dual-deployment-operator/cutover

# ---- EDIT THESE for your candidate -------------------------------------------
OPERATOR=<operator>              # e.g. disco, kube-state-metrics, metal-operator …
CLUSTER=m-qa-de-200              # target cluster short name
TARGET_CTX=m-qa-de-200           # kube context for the target/shoot cluster
SEED_CTX=a-qa-de-200             # kube context for the seed cluster
NAMESPACE=shoot--cp--m-qa-de-200 # seed namespace the legacy release lives in
OUTAGE_BUDGET_MIN=20             # must equal the --outage-budget used on the real run
LEGACY_CHART_SRC=<path-or-oci>   # source that produced the INSTALLED legacy release (see Step 2)
# ------------------------------------------------------------------------------

EV=.evidence/${OPERATOR}-${CLUSTER}      # evidence dir (gitignored via /.evidence/)
ID=$EV/identity.json
mkdir -p "$EV"
```

Everything else (release name, DDO CR name, Deployment, CRD groups, protected MRs, freeze
kinds, owned-by label, whether the operator has CRDs at all) comes from
`profiles/<operator>…env` — `load_profile` resolves `<operator>-operator-remote.env` →
`<operator>-remote.env` → `<operator>.env` in that order. **Do not hand-edit those values.**

> Per-operator shape differences you do **not** configure here — the profile carries them:
> - `NO_CRDS=1` → operator ships no CRDs, no data CRs, no baselines (e.g. kube-state-metrics).
> - `OPERAND_CHART_DIR` **unset** → delivered by DDO `source.kustomize`, not Helm (e.g.
>   ipam-capi-remote); Step 3 renders with `kustomize`/the overlay instead of `helm template`,
>   and `ddoCRManifest` uses `spec.source.kustomize` instead of `spec.source.helm`.
> - `PROTECT_MRS` / `BASELINE_SNAPSHOT_KINDS_*` non-empty → the operator has out-of-band data
>   (CRs/pools) the cutover snapshots and asserts survive (e.g. ipam pools).

---

## Step 1 — generate `identity.json` (the authority every file binds to)

```bash
bash -c "source ./cutover-ddo.sh
OPERATOR=$OPERATOR; CLUSTER=$CLUSTER
TARGET_CTX=$TARGET_CTX; SEED_CTX=$SEED_CTX
NAMESPACE=$NAMESPACE; OUTAGE_BUDGET_MIN=$OUTAGE_BUDGET_MIN
load_profile >&2
run_identity" > "$ID"
cat "$ID"
```

This sources the engine functions **without running any cluster calls** and prints the exact
run identity. `OUTAGE_BUDGET_MIN=20` → `budgetSeconds "1200"`; the real run **must** use the
same `--outage-budget` so the identities match. Every evidence file embeds this object; the
contract compares it as a **dict**, so whitespace/key order are irrelevant — only values matter.

> Never initialise a real active run just to obtain an identity: an incomplete active capture
> deliberately cannot be overwritten or resumed. Generate it with the one-liner above instead.

---

## Step 2 — package the EXACT installed legacy chart + hash it

`--legacy-chart-archive` is required, and `capture_evidence` **re-hashes the archive** and
compares it to `readiness.legacyArchiveSha256`. The bytes must reproduce the **installed
release**, not merely match chart name+version.

Find the installed chart/version first:

```bash
u8s helm --kube-context=$SEED_CTX -n=$NAMESPACE list --all --output=json \
  | python3 -c 'import json,sys;[print(r["name"],r["chart"],r["status"],r["revision"]) for r in json.load(sys.stdin)]'
```

Then obtain the archive from the **same source that produced that revision**:

```bash
# Preferred: pull the exact published chart the admin pipeline installed, e.g.
# helm pull oci://<registry>/<chart> --version <installed-version> -d /tmp
# Fallback (only if you trust the working tree is at the installed ref):
helm package "$LEGACY_CHART_SRC" -d /tmp
#   → /tmp/<chart>-<version>.tgz

ARCHIVE=/tmp/<chart>-<version>.tgz
python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$ARCHIVE"
```

Put that 64-hex digest into `readiness.json › legacyArchiveSha256`, and record in
`legacyArchiveProvenance` **how** the bytes reproduce the installed revision.

---

## Step 3 — render the seed + shoot delivery artifacts

These become `seedRender.json` / `shootRender.json` (read by **fixed name**), each a nonempty
k8s JSON **List**. The DDO operand chart renders twice by mode.

**Helm-delivered operators** (`OPERAND_CHART_DIR` set):

```bash
CHART=<path-to>/system/<operator>-remote-ddo    # the -ddo operand chart
helm template $RELEASE "$CHART" --namespace "$NAMESPACE" --set mode=seed  [extra --set …] > /tmp/seed.yaml
helm template $RELEASE "$CHART" --namespace "$NAMESPACE" --set mode=shoot [extra --set …] > /tmp/shoot.yaml
```

Use `-f <values>.yaml` instead of `--set` if any value contains a URL or `=` (bare `--set` of a
URL silently renders empty). Check the operand chart's own `tests/render-modes.sh` for the
canonical invocation and the expected object inventory.

**Kustomize-delivered operators** (`OPERAND_CHART_DIR` unset, e.g. ipam): render the overlay
seed/shoot paths with `kustomize build` instead.

Wrap each rendered stream into a k8s List and hash it:

```bash
for m in seed shoot; do
  python3 - "/tmp/$m.yaml" "$EV/${m}Render.json" <<'PY'
import sys,yaml,json
docs=[d for d in yaml.safe_load_all(open(sys.argv[1])) if d]
json.dump({"apiVersion":"v1","kind":"List","items":docs},
          open(sys.argv[2],"w"),separators=(",",":"),sort_keys=True)
PY
  python3 -c "import hashlib,sys;print(sys.argv[1],hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$EV/${m}Render.json"
done
```

> Rendered Secrets often carry **empty** placeholder data (Gardener/DDO fill them at runtime) —
> confirm no real Secret value is baked in. Never commit populated Secrets.

---

## Step 4 — build `ddoCRManifest.json` (the intended CR you will apply)

A k8s List with **exactly one** `DualDeploymentOperator`, `metadata.name = <DDO_CR from profile>`,
`metadata.namespace = $NAMESPACE`, with the real `spec` (shootNamespace, shootAccess.server, and
`spec.source.helm` **or** `spec.source.kustomize` depending on delivery). Model it on a live
sibling CR on the seed (`u8s kubectl --context=$SEED_CTX -n=$NAMESPACE get dualdeploymentoperator
<sibling> -o yaml`) and, once the operator is declared in kube-secrets
`admin-k3s/…/dual-deployment-operator.yaml`, re-render it from those real admin values so it is
byte-for-byte what you will apply. Hash it the same way as Step 3.

---

## Step 5 — fill the `<<< REVIEW >>>` human attestations + refresh timestamps

Open `freeze.json` and `readiness.json`. Each `<<< REVIEW >>>` is a claim only a human can make.
The contract requires these **nonempty strings** (base contract, same for every operator):

**freeze.json** — `reconciler`, `originalState`, `freezeProof`, `restoreOnSuccess`,
`restoreOnRollback`, `restoreOnInterruption`; booleans `legacyDesiredStateDisabled: true`,
`restorationAvoidsDualOwnership: true`.
- `freezeProof` = observed proof the reconciler (usually the `<release>-admin-k3s` Concourse
  pipeline) is **paused** so it won't re-apply — e.g.
  `fly -t <target> pause-pipeline -p <release>-admin-k3s` output + timestamp, and confirm the
  release stays at its current revision. **Scaling the Deployment alone is not accepted.**

**readiness.json** — `installedDDO`, `installedAdmin`, `sourceResolution`, `expectedOwnerValue`,
`releasePublicationProof`, `legacyArchiveProvenance`, `legacyArchiveSha256`; booleans
`sourcePublished: true`, `actualRendersReviewed: true`, `legacyArchiveMatchesInstalledRelease: true`.
- `legacyArchiveSha256` = the real digest from Step 2.
- `sourceResolution` / `releasePublicationProof` = resolve the immutable operand source and prove
  the installed delivery path can fetch it (for Helm/OCI:
  `helm show chart oci://<registry>/<operator>-remote-ddo --version <v>` — the chart must be
  **published before the CR merges**, else `SeedRenderFailed`).

`expectedOwnerValue` is machine-derivable, not a guess: first 16 hex of
`sha256("<namespace>/<DDO_CR>")` (DDO `OwnedByValue`,
`dual-deployment-operator/internal/manifest/manifest.go`):

```bash
python3 -c "import hashlib;print(hashlib.sha256(b'$NAMESPACE/'+b'<DDO_CR>').hexdigest()[:16])"
```

**acceptance.json** — `functionalChecks`, `doNoHarmChecks`. Fill these **later, at verify phase**
(post-handoff functional probes); not needed for the uninstall.

**Timestamps** — `verifiedAtEpoch` must be an integer within **24h** of the real run and not in
the future. Refresh all three right before running:

```bash
NOW=$(date +%s)
for f in freeze readiness acceptance; do
  python3 - "$EV/$f.json" "$NOW" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["verifiedAtEpoch"]=int(sys.argv[2])
json.dump(d,open(p,"w"),indent=2,sort_keys=True)
PY
done
```

---

## Step 6 — validate before running (structural)

```bash
for k in freeze readiness acceptance; do
  python3 lib/cutover-evidence.py contract "$EV/$k.json" "$ID" "$k" && echo "PASS $k"
done
```

This checks identity match, age, required keys/booleans, and artifact hashes. It **cannot**
judge whether your prose is true — that is on the human attester and independent review.

---

## Step 7 — run the real uninstall, then verify

```bash
./cutover-ddo.sh --operator $OPERATOR --phase uninstall --cluster $CLUSTER \
  --seed-context $SEED_CTX \
  --outage-budget $OUTAGE_BUDGET_MIN \
  --legacy-chart-archive "$ARCHIVE" \
  --freeze-evidence    "$EV/freeze.json" \
  --readiness-evidence "$EV/readiness.json"
```

- Exit **0** = gate/phase passed · **2** = gate abort (read the message) · **20** = uninstall +
  teardown barrier complete · **30** = outage deadline exhausted (keep the reconciler frozen,
  manual recovery only).
- After exit 20, activate the DDO CR (declare the operator in kube-secrets admin values;
  publish-before-merge the operand chart).

Later, **verify** phase — fill `acceptance.json` first, then resume with **identical**
coordinates/profile/budget:

```bash
./cutover-ddo.sh --operator $OPERATOR --phase verify --resume \
  --cluster $CLUSTER --seed-context $SEED_CTX --outage-budget $OUTAGE_BUDGET_MIN \
  --state-dir "$HOME/.local/state/ddo-cutover/${OPERATOR}-${CLUSTER}" \
  --legacy-chart-archive "$ARCHIVE" \
  --freeze-evidence    "$EV/freeze.json" \
  --readiness-evidence "$EV/readiness.json" \
  --acceptance-evidence "$EV/acceptance.json"
```

> `--state-dir` is the **root** (`…/<operator>-<cluster>`), not its `active/` child. `--resume`
> requires the original explicit `--seed-context`. An IPAM-class operator additionally has
> IPAM-only readiness/acceptance fields enforced by the contract — see `SAFETY-EVIDENCE.md`
> §"Additional IPAM readiness"; for all other operators the base contract above is complete.

---

## Per-operator quick reference

| Input | Where it comes from |
|-------|--------------------|
| release, DDO CR, Deployment, CRD groups, protected MRs, freeze kinds, owned-by label, `NO_CRDS` | `profiles/<operator>…env` (never hand-edit) |
| legacy chart archive + its sha256 | Step 2 — the exact installed chart |
| seed/shoot renders | Step 3 — the `-ddo` operand chart (Helm) or the kustomize overlay |
| intended CR | Step 4 — modeled on the live sibling / real admin values |
| freeze/readiness/acceptance prose | Step 5 — human attestation |

Each candidate gets its own gitignored `.evidence/<operator>-<cluster>/` dir. Existing worked
examples live under `.evidence/disco-m-qa-de-200/` and `.evidence/kube-state-metrics-m-qa-de-200/`.
