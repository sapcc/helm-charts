# metal-operator-remote-v2 — E2E Demo Script — Work Plan

## TL;DR (For humans)

**What you'll get:** One self-contained, demo-oriented bash script at
`system/metal-operator-remote-v2/examples/demo-e2e.sh` that drives the full
operator-native delivery flow for a live audience, in five phases:

0. **Cleanup** — remove all prior test resources (CR, seed render, shoot render incl. CRDs) so the demo starts pristine.
1. **Install** — install the `dual-deployment-operator` on seed `rt-qa-de-1` and observe it come up healthy.
2. **Apply CR + verify** — apply the example `DualDeploymentOperator` CR, watch it reconcile to `Ready=True`, then verify the SEED render (metal-operator controller working) and the SHOOT render (CRDs, RBAC, VWC with injector-stamped caBundle) both landed.
3. **Mutations** — 5 mutation/self-heal tests, each verified after a forced reconcile.
4. **Deletion** — delete the CR, verify clean teardown (no finalizer deadlock; CRDs retained by design).

**Demo UX:** the script pauses (press-Enter) before AND after every microstep, printing each command and its result in colour so an audience can follow. A `--no-pause` flag runs it straight through; `--from N` starts at a phase.

**Why this shape:** every command is lifted verbatim from the already-executed
`examples/TEST-PLAN.md`, so nothing is invented — the script just wraps the proven
flow in narration + pauses + pass/fail assertions. It never touches production
`m-qa-de-1`.

**Prerequisites (script does NOT build these):** chart `0.1.0` already on keppel;
operator image already pushed (passed via `DDO_IMAGE_REPO`/`DDO_IMAGE_TAG`); u8s
contexts `rt-qa-de-1` + `g-qa-de-1`; the throwaway shoot `test-qa-de-1` exists;
operator install-chart dir passed via `DDO_CHART_DIR`.

Your next move: approve, then run `/start-work` — the implementer writes the file
below verbatim and `chmod +x` it. **This is a chore/tooling deliverable; TDD does
not apply (no unit test for a demo driver). Verification = `bash -n` syntax check +
`shellcheck` (if available) + a `--no-pause --from 0` dry read.**

---

> TL;DR (machine): Author `system/metal-operator-remote-v2/examples/demo-e2e.sh`
> (bash, `chmod +x`) verbatim from the CODE BLOCK below. 5 phases (cleanup/install/
> apply+verify/mutations/deletion), press-Enter pause at every microstep (`--no-pause`
> to disable, `--from N` to skip). Seed via `u8s kubectl --context rt-qa-de-1` +
> `U8S_CONTEXT=rt-qa-de-1 u8s helm3 -- upgrade --install`. Shoot via freshly-minted
> Gardener AdminKubeconfigRequest (TTL 3600s) refreshed per phase. Install sets
> `manager.image.repository/tag`, `manager.envOverrides.ENABLE_WEBHOOKS=false`,
> `shootRbac.enabled=true`. Mutations account for the one-cycle prune lag via a
> `force_reconcile` helper that annotates the CR and waits for `.status.lastReconcile`
> to advance. Deletion asserts clean finalizer completion + CRD retention. Assumes
> chart 0.1.0 on keppel + operator image already pushed (env vars). Verification:
> `bash -n`, `shellcheck` if present, `--no-pause` rehearsal.

## Scope

### Must have
- Single file `system/metal-operator-remote-v2/examples/demo-e2e.sh`, executable, written **verbatim** from the CODE BLOCK below.
- Phase 0 cleanup deletes the CR (finalizer-clear fallback if wedged), uninstalls the operator release, deletes the operator CRD, sweeps owned seed objects + named seed objects, and sweeps shoot objects incl. the `metal.ironcore.dev` CRDs.
- Phase 1 installs via `u8s helm3` with the three required `--set`s; verifies CRD present, controller `readyReplicas>=1`, shoot-access token minted, no crashloop in logs.
- Phase 2 applies the CR, polls `Ready`, verifies SEED render (controller ready, sidecar, macdb resolved, svc/ingress/np/cm) and SHOOT render (metal CRDs, VWC url+label, **caBundle length>=100 = the key proof**, RBAC/SA/oidc bindings/metal-servers ns), plus the prod no-impact check.
- Phase 3 runs M1–M5 (drift correction, caBundle no-clobber, macdb self-heal, transform change+revert, CR-update prune) each gated on `force_reconcile`.
- Phase 4 deletes the CR with a timed `--wait`, asserts seed+shoot render gone and CRDs retained.
- Pause at EVERY microstep (`pause()` reads from `/dev/tty`); `--no-pause` and `--from N` flags honoured.
- Preflight validates CLIs (`u8s`,`kubectl`,`yq`), the two image env vars, `DDO_CHART_DIR`, the CR file, seed + garden reachability.

### Must NOT do
- No building/pushing of the chart or operator image (assumed present).
- No edits to the CR, chart templates, TEST-PLAN, or the operator repo.
- No touching production `m-qa-de-1` (only a read-only no-impact check).
- No committing the minted shoot kubeconfig (written to a dot-file, `chmod 600`, removed at end).

## Grounding (verified facts the script encodes)
- CR name `metal-operator-remote-v2`, ns `shoot--cp--test-qa-de-1`, `shootNamespace: kube-system`, `applyOrder: ShootFirst` — from `examples/dualdeploymentoperator-test-qa-de-1.yaml`.
- Transform order: `[0]=rewriteWebhookURL`, `[1]=patch`(label) — so the M4 JSON-patch path is `/spec/transformations/1/patch/strategicMerge/metadata/labels/...` (verified against the CR file).
- Install `--set`s + why (`ENABLE_WEBHOOKS=false` with `certManager.enabled=false`; `shootRbac.enabled=true` provisions the dedicated `dual-deployment-operator-shoot-applier` SA + `dual-deployment-operator-shoot-access` Secret) — from TEST-PLAN §2b + operator `chart/values.yaml` + `chart/Chart.yaml` (appVersion 0.1.0).
- Operator install-chart release name `dual-deployment-operator`; controller deploy `dual-deployment-operator-controller-manager`.
- Seed object names: `metal-operator-controller-manager`, `macdb`, `remote-kubeconfig`, `metal-operator-remote-kubeconfig`, `metal-operator-remote-webhook-service`, `metal-operator-metal-registry-service`, `metal-operator-metal-registry-ingress` — from TEST-PLAN §4.
- Shoot object names: VWC `metal-operator-validating-webhook-configuration`, ClusterRoles `metal-api-viewer`/`metal-operator-dns-records`/`metal-operator-webhook-injector`, SA `metal-operator-controller-manager` in `kube-system`, ns `metal-servers` — from TEST-PLAN §5.
- Prune is SAME-CYCLE (verified against operator HEAD `b9b68f7`): the reconcile that processes a CR change re-renders (removed object absent) AND prunes it against the top-of-cycle prior inventory (`prevSeedResources`/`prevShootResources`) before the status write — `internal/controller/dualdeploymentoperator_controller.go` (prune step 8 → status write step 9). No one-cycle lag. Hence M5 uses a SINGLE `force_reconcile` and asserts same-cycle prune. (An earlier revision had a lag + degraded-path orphaning; both fixed by archived change `2026-08-09-fix-prune-inventory-orphaning`, Option C, aligning with the Flux/Argo same-cycle norm.) Cross-doc: `dual-deployment-operator/docs/prune-rerender-timing.md`.
- Shoot reachable only via Gardener `AdminKubeconfigRequest` on `g-qa-de-1` (u8s can't see `test-qa-de-1`) — from TEST-PLAN open item 6.
- `owned-by` label value format is `<cr-namespace>_<cr-name>` (`manifest.OwnedByValue`) → `shoot--cp--test-qa-de-1_metal-operator-remote-v2`, used for the sweep selectors.

## Open risk / to sanity-check on first live run
- **M5 prune assertion**: the exact dns-record ConfigMap name is not pinned in TEST-PLAN; the script probes both a guessed name (`bmc-dns-record-template`) and the `owned-by`-labelled ConfigMap set filtered by `dns`. If neither matches, it warns (non-fatal) rather than failing the demo. First live run should confirm the real ConfigMap name and pin it.
- **M4 patch path** assumes transform index `1` is the label patch — correct for the current CR; if the CR's transform order changes the patch warns instead of aborting.
- **`--wait` on helm install**: uses `--wait --timeout=180s`; if the seed is slow, bump the timeout.

## Refinement (2026-08-08): split cleanup into a standalone script

User directive: **the cleanup must live in its own script**, and it must remove ALL
installation — the operator release AND its CRDs on the seed, plus the entire shoot
render INCLUDING the `metal.ironcore.dev` CRDs. Design:

- **New `examples/cleanup.sh`** — standalone, demo-narrated (same colour/pause helpers,
  `--no-pause` flag). It performs the complete teardown so a demo can start pristine or
  a test env can be fully reset:
  1. Delete the DDO CR (finalizer-clear fallback if wedged).
  2. `helm uninstall` the operator release on the seed.
  3. Delete the operator CRD `dualdeploymentoperators.dual-deployment-operator.cc.sap` on the seed (chart keeps it by default — this script forces removal).
  4. Sweep seed-render objects (owned-by label + named objects).
  5. Mint the shoot admin kubeconfig, then sweep the shoot render: VWC, ClusterRoles, ClusterRoleBindings, `metal-servers` ns, the `kube-system` SA, **AND the `metal.ironcore.dev` CRDs** (this deletes any CRs of those kinds too).
  6. Confirm pristine on both clusters.
  Shared helpers (colours, `pause`, `run`, `S/SC/H`, `refresh_shoot_kubeconfig`) are
  duplicated into `cleanup.sh` so it is fully standalone (no sourcing required).
- **`demo-e2e.sh` no longer contains inline Phase 0.** It shells out to `cleanup.sh`
  (`"$SCRIPT_DIR/cleanup.sh" ${DO_PAUSE:+} ...`) at the start unless `--from` skips it,
  and its remaining phases stay Install / Apply+Verify / Mutations / Deletion. The
  header comment + `--from` mapping are updated accordingly (Phase 0 = "run cleanup.sh").
  Deletion (Phase 4) is the operator-driven CR teardown demo; full CRD removal is
  cleanup.sh's job, not Phase 4's (Phase 4 asserts CRDs are RETAINED by design, which is
  the correct operator behaviour — cleanup.sh is the explicit "nuke everything" path).

## Refinement (2026-08-08, #2): cleanup.sh must be IDEMPOTENT

User directive: running `cleanup.sh` against an already-clean environment, or twice
in a row, must succeed cleanly — no hard aborts and no misleading red failures. Fixes
required:

1. **preflight must not abort on a clean env.** `preflight_lite` currently `run_check`s
   `get ns $CP_NS` and hard-exits if absent. Change to: tools check stays fatal; seed
   reachability check must tolerate a missing CP namespace (warn + continue if the ns is
   gone, only abort if the SEED itself is unreachable — distinguish "cannot reach seed"
   from "ns not found").
2. **No misleading `(exit N)` on already-absent resources.** Every delete is already
   `--ignore-not-found` (good). But the metal-CRD grep pipeline (`... get crd -o name |
   grep metal.ironcore.dev | xargs -r ... delete`) exits non-zero under `pipefail` when
   `grep` matches nothing, printing a scary warning on a clean shoot. Make that pipeline
   return 0 on zero matches (e.g. `grep ... || true` inside the `bash -c`, or `|| true`
   on the whole `run`).
3. **Fix the inverted "confirm pristine" checks.** Lines like
   `run S get dualdeploymentoperator 2>/dev/null || ok "no CR"` are unreliable (kubectl
   get on an empty set may exit 0 with "No resources found", so the `|| ok` never fires,
   or prints a red exit on error). Replace with an explicit presence test that prints a
   clean ✅ when the resource is absent and only a ⚠️ when it unexpectedly remains — using
   the helpers, not `run ... || ok`.
4. **Idempotent by construction:** a second consecutive `--no-pause` run must produce
   only ✅/ℹ️ lines and exit 0 — no ❌, no unhandled `(exit N)`. Verify by reasoning
   through each step against a clean-env assumption (live run is the user's gate).

Keep the script standalone, demo-narrated, and non-destructive to prod. `bash -n` and
`shellcheck -S error` must stay clean.

## Tasks

- [x] `system/metal-operator-remote-v2/examples/demo-e2e.sh`: create the file with EXACTLY the contents of the CODE BLOCK below, then `chmod +x` it — expect a runnable demo driver
- [x] Verify `bash -n system/metal-operator-remote-v2/examples/demo-e2e.sh` exits 0 (syntax) — expect no output, exit 0
- [x] `system/metal-operator-remote-v2/examples/cleanup.sh`: create a standalone demo-narrated cleanup script that removes ALL installation (operator release + CRD on seed; full shoot render INCLUDING `metal.ironcore.dev` CRDs), `chmod +x` — expect a runnable standalone teardown that leaves both clusters pristine [DONE: 255 lines, idempotent — preflight tolerates missing CP ns, metal-CRD grep guarded with `{ grep || true; }`, explicit if/else confirm-pristine]
- [x] `system/metal-operator-remote-v2/examples/demo-e2e.sh`: remove the inline `phase0_cleanup`, call `cleanup.sh` for the cleanup phase, update the header comment + `--from 0` mapping — expect the demo delegates cleanup to cleanup.sh and still runs Install→Apply→Mutate→Delete [DONE: phase0_cleanup removed (0 defs), line 506 invokes `"$SCRIPT_DIR/cleanup.sh"` with --no-pause propagated, header updated]
- [x] Verify `bash -n` exits 0 for BOTH `cleanup.sh` and `demo-e2e.sh` — expect no output, exit 0 each [DONE: both exit 0]
- [x] If `shellcheck` is installed, run it on BOTH scripts and fix only real errors (SC2086 on the intentional `run bash -c "…"` blocks may be ignored) — expect no error-level findings [DONE: `shellcheck -S error` exit 0, no error-level findings]
- [x] Update `examples/README.md`: add a `cleanup.sh` row (`standalone teardown — removes ALL installation incl. CRDs on seed + shoot`) and refine the `demo-e2e.sh` row to note it calls cleanup.sh first — expect the README lists both scripts [DONE: both rows present, lines 13-14]

## Refinement (2026-08-08, #3): fixed DDO_IMAGE_REPO + DDO_CHART_DIR, interactive tag

User directive: DDO_IMAGE_REPO and DDO_CHART_DIR are fixed — bake them as defaults into
both scripts (no need to export); DDO_IMAGE_TAG is prompted interactively at runtime.

- [x] Both scripts: bake `DDO_IMAGE_REPO="${DDO_IMAGE_REPO:-keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator}"` and `DDO_CHART_DIR="${DDO_CHART_DIR:-/Users/D065300/IdeaProjects/sapcc/dual-deployment-operator/chart}"` (still env-overridable). cleanup.sh gets both for config symmetry (commented unused). [DONE: demo-e2e.sh L62/L66; cleanup.sh L44-46]
- [x] demo-e2e.sh: add `prompt_tag()` reading DDO_IMAGE_TAG from `/dev/tty` (loop until non-empty) when unset; preflight image-env hard-fail replaced by `prompt_tag`; chart-dir Chart.yaml check retained. [DONE: prompt_tag L134-155, called in preflight L187; env-preset short-circuits with no prompt]
- [x] Verify `bash -n` (both exit 0) + `shellcheck -S error` (both clean) + env-preset dry-run honours preset tag without prompting. [DONE: all green]

## Verification (no TDD — this is a demo driver)
- `bash -n` clean.
- `shellcheck` clean of error-level findings (warnings on deliberate `bash -c` dynamic commands are acceptable).
- Optional human rehearsal: `DDO_IMAGE_REPO=… DDO_IMAGE_TAG=… DDO_CHART_DIR=… ./demo-e2e.sh --no-pause` against the test seed (the real acceptance gate is the live run, owned by the user).

---

## CODE BLOCK — write this verbatim to `system/metal-operator-remote-v2/examples/demo-e2e.sh`

```bash
#!/usr/bin/env bash
# =============================================================================
#  metal-operator-remote-v2 — END-TO-END DEMO SCRIPT
# =============================================================================
#  Drives the full operator-native delivery flow for a live audience:
#
#    Phase 0  Cleanup    — remove ALL prior test resources (CR, seed render,
#                          shoot render incl. CRDs) so we start pristine.
#    Phase 1  Install     — install the dual-deployment-operator on seed
#                          rt-qa-de-1, observe it come up healthy.
#    Phase 2  Apply CR     — apply the example DualDeploymentOperator CR, watch
#                          it reconcile; verify the SEED render (metal-operator
#                          controller + friends) and the SHOOT render (CRDs,
#                          RBAC, VWC with injected caBundle) both landed.
#    Phase 3  Mutations   — run 5 mutation tests, verifying self-heal / prune /
#                          drift-correction after each.
#    Phase 4  Deletion    — delete the CR, verify the operator tears down both
#                          renders cleanly (no finalizer deadlock).
#
#  DEMO MODE: the script PAUSES before and after every microstep and waits for
#  you to press Enter, printing each command and its result clearly so the
#  audience can follow along. Run with --no-pause to disable pauses.
#
#  PREREQUISITES (assumed already done — the script does NOT build these):
#    * metal-operator-remote-v2 chart 0.1.0 pushed to keppel
#        oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-operator-remote-v2:0.1.0
#    * dual-deployment-operator image built + pushed to a registry rt-qa-de-1
#      can pull. Provide it via env vars (see CONFIG below).
#    * u8s configured with contexts rt-qa-de-1 (seed) and g-qa-de-1 (garden).
#    * The throwaway shoot test-qa-de-1 exists and is Healthy.
#    * The operator install chart source is available locally (DDO_CHART_DIR).
#
#  USAGE:
#    export DDO_IMAGE_REPO=keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator
#    export DDO_IMAGE_TAG=<tag>
#    export DDO_CHART_DIR=/path/to/dual-deployment-operator/chart
#    ./demo-e2e.sh                 # full demo, pauses at every step
#    ./demo-e2e.sh --no-pause      # run straight through (rehearsal / CI-ish)
#    ./demo-e2e.sh --from 2        # skip to a phase (0-4); earlier phases skipped
#
#  This script is deliberately verbose and defensive. It NEVER touches the
#  production metal shoot m-qa-de-1.
# =============================================================================

set -uo pipefail

# -----------------------------------------------------------------------------
# CONFIG — override via environment.
# -----------------------------------------------------------------------------
SEED_CTX="${SEED_CTX:-rt-qa-de-1}"                        # seed cluster (u8s context)
GARDEN_CTX="${GARDEN_CTX:-g-qa-de-1}"                     # garden cluster (u8s context)
SHOOT_NAME="${SHOOT_NAME:-test-qa-de-1}"                  # throwaway test shoot
CP_NS="${CP_NS:-shoot--cp--test-qa-de-1}"                 # shoot CP namespace on the seed
SHOOT_RENDER_NS="${SHOOT_RENDER_NS:-kube-system}"         # spec.shootNamespace (load-bearing)
CR_NAME="${CR_NAME:-metal-operator-remote-v2}"            # DualDeploymentOperator name
RELEASE="${RELEASE:-dual-deployment-operator}"            # operator helm release name
PROD_CP_NS="${PROD_CP_NS:-shoot--cp--m-qa-de-1}"          # prod CP ns — for the no-impact check

# Operator image (MUST be pullable by the seed — no ghcr default here).
DDO_IMAGE_REPO="${DDO_IMAGE_REPO:-}"
DDO_IMAGE_TAG="${DDO_IMAGE_TAG:-}"

# Operator install-chart source directory.
DDO_CHART_DIR="${DDO_CHART_DIR:-}"

# The example CR lives next to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CR_FILE="${CR_FILE:-$SCRIPT_DIR/dualdeploymentoperator-test-qa-de-1.yaml}"

# Where to write the freshly-minted shoot admin kubeconfig (short-TTL).
SHOOT_KUBECONFIG="${SHOOT_KUBECONFIG:-$SCRIPT_DIR/.demo-$SHOOT_NAME.kubeconfig}"
SHOOT_KUBECONFIG_TTL="${SHOOT_KUBECONFIG_TTL:-3600}"      # seconds; Gardener AdminKubeconfigRequest

DO_PAUSE=1
FROM_PHASE=0

# -----------------------------------------------------------------------------
# arg parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pause) DO_PAUSE=0; shift ;;
    --from)     FROM_PHASE="${2:-0}"; shift 2 ;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# -----------------------------------------------------------------------------
# presentation helpers
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLU=$'\033[36m'; MAG=$'\033[35m'
else
  B=""; DIM=""; R=""; RED=""; GRN=""; YEL=""; BLU=""; MAG=""
fi

PHASE_LABEL=""

hr()   { printf '%s\n' "${DIM}────────────────────────────────────────────────────────────────────────────${R}"; }
phase(){ echo; printf '%s\n' "${MAG}${B}╔══════════════════════════════════════════════════════════════════════════╗${R}";
         printf '%s\n' "${MAG}${B}║  PHASE $1 — $2${R}";
         printf '%s\n' "${MAG}${B}╚══════════════════════════════════════════════════════════════════════════╝${R}"; PHASE_LABEL="$1"; }
step() { echo; printf '%s\n' "${BLU}${B}▶ STEP: $*${R}"; }
note() { printf '%s\n' "${DIM}  ↳ $*${R}"; }
ok()   { printf '%s\n' "${GRN}  ✅ $*${R}"; }
warn() { printf '%s\n' "${YEL}  ⚠️  $*${R}"; }
err()  { printf '%s\n' "${RED}  ❌ $*${R}"; }

# pause() — wait for Enter (demo mode). Skipped by --no-pause.
pause() {
  [[ "$DO_PAUSE" -eq 0 ]] && return 0
  printf '%s' "${YEL}${B}    [press Enter to continue]${R}"
  read -r _ < /dev/tty || true
}

# run() — show the command, run it, show output. Non-fatal by default so a demo
# keeps flowing; use run_check() when a non-zero exit should abort.
run() {
  echo; printf '%s\n' "${B}\$ $*${R}"; hr
  "$@"; local rc=$?
  hr
  [[ $rc -ne 0 ]] && warn "(exit $rc)"
  return $rc
}

run_check() {
  run "$@" || { err "Command failed and this step is required. Aborting."; exit 1; }
}

# expect_ge() — assert a numeric value is >= a threshold; print a clear verdict.
expect_ge() { # $1=actual $2=min $3=label
  if [[ "${1:-0}" -ge "$2" ]]; then ok "$3: got $1 (expected >= $2)"; else err "$3: got $1 (expected >= $2)"; fi
}

# seed / shoot command shortcuts
S()  { u8s kubectl --context "$SEED_CTX" -n "$CP_NS" "$@"; }
SC() { u8s kubectl --context "$SEED_CTX" "$@"; }               # seed, cluster-scoped
H()  { kubectl --kubeconfig "$SHOOT_KUBECONFIG" "$@"; }        # shoot (admin kubeconfig)

# -----------------------------------------------------------------------------
# preflight
# -----------------------------------------------------------------------------
preflight() {
  phase "PRE" "Preflight — verify tools, contexts, artifacts, and CR file"

  step "Check required CLIs are present"
  local missing=0
  for c in u8s kubectl yq; do
    if command -v "$c" >/dev/null 2>&1; then ok "found: $c"; else err "missing: $c"; missing=1; fi
  done
  [[ $missing -eq 1 ]] && { err "Install the missing tools and re-run."; exit 1; }

  step "Check operator image env vars are set"
  if [[ -z "$DDO_IMAGE_REPO" || -z "$DDO_IMAGE_TAG" ]]; then
    err "DDO_IMAGE_REPO and DDO_IMAGE_TAG must be set (the seed cannot pull the ghcr default)."
    note "example: export DDO_IMAGE_REPO=keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator"
    note "         export DDO_IMAGE_TAG=<tag>"
    exit 1
  fi
  ok "operator image: $DDO_IMAGE_REPO:$DDO_IMAGE_TAG"

  step "Check operator install-chart dir"
  if [[ -z "$DDO_CHART_DIR" || ! -f "$DDO_CHART_DIR/Chart.yaml" ]]; then
    err "DDO_CHART_DIR must point at the operator install chart (dir containing Chart.yaml)."
    exit 1
  fi
  ok "chart dir: $DDO_CHART_DIR"

  step "Check the example CR file exists"
  if [[ ! -f "$CR_FILE" ]]; then err "CR file not found: $CR_FILE"; exit 1; fi
  ok "CR file: $CR_FILE"

  step "Confirm seed context reachable ($SEED_CTX)"
  run_check bash -c "u8s kubectl --context '$SEED_CTX' get ns '$CP_NS' -o name"
  ok "seed reachable; CP namespace present"

  step "Confirm garden context reachable ($GARDEN_CTX) — needed to mint shoot kubeconfig"
  run_check bash -c "u8s kubectl --context '$GARDEN_CTX' -n garden get shoot '$SHOOT_NAME' -o jsonpath='{.status.lastOperation.state}{\"\\n\"}'"
  ok "garden reachable; test shoot visible"

  step "Verify the chart is pullable from keppel (informational)"
  run helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-operator-remote-v2 --version 0.1.0 \
    || warn "helm show failed — ensure keppel creds are present; the operator pulls it in-cluster regardless."

  pause
}

# -----------------------------------------------------------------------------
# shoot kubeconfig (Gardener AdminKubeconfigRequest — u8s cannot reach the shoot)
# -----------------------------------------------------------------------------
refresh_shoot_kubeconfig() {
  step "Mint a fresh admin kubeconfig for the shoot ($SHOOT_NAME, TTL ${SHOOT_KUBECONFIG_TTL}s)"
  note "u8s does not know test-qa-de-1 (not registry-enrolled). We ask the garden"
  note "cluster for a short-lived admin kubeconfig via AdminKubeconfigRequest."
  local req
  req=$(printf '%s' "{\"apiVersion\":\"authentication.gardener.cloud/v1alpha1\",\"kind\":\"AdminKubeconfigRequest\",\"spec\":{\"expirationSeconds\":${SHOOT_KUBECONFIG_TTL}}}")
  if printf '%s' "$req" \
      | u8s kubectl --context "$GARDEN_CTX" create -f - \
        --raw "/apis/core.gardener.cloud/v1beta1/namespaces/garden/shoots/${SHOOT_NAME}/adminkubeconfig" \
      | yq -r '.status.kubeconfig' | base64 -d > "$SHOOT_KUBECONFIG" 2>/dev/null \
      && [[ -s "$SHOOT_KUBECONFIG" ]]; then
    chmod 600 "$SHOOT_KUBECONFIG"
    ok "shoot kubeconfig written: $SHOOT_KUBECONFIG"
    run H get --raw='/readyz' || warn "shoot /readyz not OK yet"
  else
    err "Failed to mint shoot kubeconfig. Shoot-render checks will be skipped."
    return 1
  fi
}

# =============================================================================
# PHASE 0 — CLEANUP
# =============================================================================
phase0_cleanup() {
  phase "0" "CLEANUP — remove all prior test resources (seed + shoot, incl. CRDs)"
  warn "This resets the demo to a pristine state. It only touches the TEST shoot."

  step "Show any existing CR (so the audience sees the starting state)"
  run S get dualdeploymentoperator -o wide || true
  pause

  step "Delete the DualDeploymentOperator CR (lets the operator tear down its renders first)"
  note "If the operator is healthy this cleanly removes both renders. If it is absent or"
  note "wedged, we fall back to clearing the finalizer so cleanup never hangs the demo."
  if S get dualdeploymentoperator "$CR_NAME" >/dev/null 2>&1; then
    run S delete dualdeploymentoperator "$CR_NAME" --wait=true --timeout=120s
    if S get dualdeploymentoperator "$CR_NAME" >/dev/null 2>&1; then
      warn "CR still present after delete — clearing finalizer (operator absent/wedged)."
      run S patch dualdeploymentoperator "$CR_NAME" --type=merge -p '{"metadata":{"finalizers":[]}}'
    fi
    ok "CR removed"
  else
    ok "no CR to delete"
  fi
  pause

  step "Uninstall the operator release from the seed (if present)"
  run bash -c "U8S_CONTEXT='$SEED_CTX' u8s helm3 -- uninstall '$RELEASE' --namespace '$CP_NS'" \
    || note "no release named $RELEASE in $CP_NS (fine)"
  pause

  step "Delete the operator CRD on the seed (chart keeps it by default: crd.keep=true)"
  run SC delete crd dualdeploymentoperators.dual-deployment-operator.cc.sap --ignore-not-found
  pause

  step "Sweep any leftover SEED-render objects owned by this CR"
  note "The operator normally prunes these, but a hard finalizer-clear can orphan them."
  local owned="dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}"
  for kind in deploy svc ingress networkpolicy secret configmap; do
    run S delete "$kind" -l "$owned" --ignore-not-found || true
  done
  # Named seed objects the chart creates (belt-and-suspenders):
  run S delete deploy metal-operator-controller-manager --ignore-not-found || true
  run S delete secret macdb remote-kubeconfig metal-operator-remote-kubeconfig --ignore-not-found || true
  pause

  step "Sweep the SHOOT-render objects (CRDs, RBAC, VWC, namespace) on the test shoot"
  if refresh_shoot_kubeconfig; then
    run H delete validatingwebhookconfiguration metal-operator-validating-webhook-configuration --ignore-not-found || true
    run H delete clusterrole metal-api-viewer metal-operator-dns-records metal-operator-webhook-injector --ignore-not-found || true
    run H delete clusterrolebinding -l "dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}" --ignore-not-found || true
    run H delete ns metal-servers --ignore-not-found || true
    note "Deleting the metal.ironcore.dev CRDs (this also removes any CRs of those kinds):"
    run bash -c "kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd -o name | grep metal.ironcore.dev | xargs -r kubectl --kubeconfig '$SHOOT_KUBECONFIG' delete --ignore-not-found" || true
    run H -n "$SHOOT_RENDER_NS" delete sa metal-operator-controller-manager --ignore-not-found || true
    ok "shoot render swept"
  else
    warn "Skipped shoot sweep (no kubeconfig). Continue only if the shoot is already clean."
  fi
  pause

  step "Confirm pristine: no CR, no operator deploy, no metal CRDs on the shoot"
  run S get dualdeploymentoperator 2>/dev/null || ok "no CR (expected)"
  run S get deploy metal-operator-controller-manager 2>/dev/null || ok "no seed workload (expected)"
  [[ -s "$SHOOT_KUBECONFIG" ]] && { run bash -c "kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd | grep -c metal.ironcore.dev || true"; }
  ok "Phase 0 complete — environment is clean."
  pause
}

# =============================================================================
# PHASE 1 — INSTALL THE OPERATOR ON THE SEED
# =============================================================================
phase1_install() {
  phase "1" "INSTALL — deploy dual-deployment-operator on seed $SEED_CTX"
  note "Installed INTO the shoot CP namespace $CP_NS (mirrors prod; the CP namespace"
  note "carries the Gardener label-gated egress policies the operator pod needs)."

  step "Install the operator via its Helm chart (u8s helm3, seed context via env)"
  note "ENABLE_WEBHOOKS=false is REQUIRED: with certManager.enabled=false the operator's"
  note "own admission webhook has no TLS cert and would CrashLoopBackOff. shootRbac.enabled"
  note "=true provisions the dedicated shoot-applier SA + the shoot-access token Secret."
  run_check bash -c "U8S_CONTEXT='$SEED_CTX' u8s helm3 -- upgrade --install '$RELEASE' '$DDO_CHART_DIR' \
    --namespace '$CP_NS' \
    --set manager.image.repository='$DDO_IMAGE_REPO' \
    --set manager.image.tag='$DDO_IMAGE_TAG' \
    --set manager.envOverrides.ENABLE_WEBHOOKS=false \
    --set shootRbac.enabled=true \
    --wait --timeout=180s"
  ok "helm upgrade --install completed"
  pause

  step "Verify the CRD is installed"
  run SC get crd dualdeploymentoperators.dual-deployment-operator.cc.sap
  pause

  step "Verify the controller pod is Running/Ready (observe installation success)"
  run S get deploy,pod -l app.kubernetes.io/name=dual-deployment-operator -o wide
  local ready
  ready=$(S get deploy "$RELEASE-controller-manager" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  expect_ge "${ready:-0}" 1 "operator controller readyReplicas"
  pause

  step "Verify the shoot-access token Secret was minted by Gardener (shootRbac bootstrap)"
  local toklen
  toklen=$(S get secret dual-deployment-operator-shoot-access -o jsonpath='{.data.token}' 2>/dev/null | wc -c | tr -d ' ')
  expect_ge "${toklen:-0}" 1 "shoot-access token length (Gardener populated)"
  pause

  step "Tail the operator log — confirm no egress/DNS/crashloop errors"
  run S logs deploy/"$RELEASE-controller-manager" --tail=25
  ok "Phase 1 complete — operator is up and healthy."
  pause
}

# =============================================================================
# PHASE 2 — APPLY THE CR + VERIFY BOTH RENDERS
# =============================================================================
phase2_apply_and_verify() {
  phase "2" "APPLY CR — reconcile, then verify SEED + SHOOT renders"

  step "Show the CR we are about to apply (source, transforms, values)"
  run bash -c "grep -vE '^\s*#' '$CR_FILE' | sed '/^\s*\$/d' | head -60"
  pause

  step "Apply the DualDeploymentOperator CR"
  run_check S apply -f "$CR_FILE"
  ok "CR applied"
  pause

  step "Watch the CR reconcile toward Ready=True (observe status in the seed)"
  note "The operator renders the chart twice, applies the shoot render, then the seed"
  note "render (applyOrder: ShootFirst), and patches the webhook caBundle via the injector."
  run bash -c "for i in \$(seq 1 30); do
    st=\$(u8s kubectl --context '$SEED_CTX' -n '$CP_NS' get ddo '$CR_NAME' -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status} {.status.conditions[?(@.type==\"Ready\")].reason}' 2>/dev/null);
    echo \"  [\$i] Ready=\$st\";
    [[ \"\$st\" == True* ]] && break;
    sleep 6;
  done"
  run S get ddo "$CR_NAME" -o jsonpath='{.status.conditions}' ; echo
  local ready
  ready=$(S get ddo "$CR_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [[ "$ready" == "True" ]] && ok "CR Ready=True" || warn "CR not Ready yet (reason above); continuing verification"
  pause

  # ---- SEED render verification ---------------------------------------------
  step "SEED render — the metal-operator controller landed in $CP_NS"
  run S get deploy metal-operator-controller-manager -o wide
  local mready
  mready=$(S get deploy metal-operator-controller-manager -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  expect_ge "${mready:-0}" 1 "metal-operator controller readyReplicas (working in seed)"
  pause

  step "SEED render — webhook-injector sidecar present on the controller"
  run bash -c "u8s kubectl --context '$SEED_CTX' -n '$CP_NS' get deploy metal-operator-controller-manager -o yaml | grep -A3 -i 'initContainers\\|webhook-injector' | head"
  pause

  step "SEED render — macdb Secret resolved by secrets-injector (0 vault refs left)"
  local vleft
  vleft=$(S get secret macdb -o jsonpath='{.data.macdb\.yaml}' 2>/dev/null | base64 -d 2>/dev/null | grep -c 'vault+kvv2' || echo 0)
  if [[ "${vleft:-1}" -eq 0 ]]; then ok "macdb resolved (0 vault+kvv2 refs remain)"; else warn "macdb still has $vleft vault refs (injector may be pending)"; fi
  pause

  step "SEED render — services, ingress, networkpolicies, remote-kubeconfig"
  run S get svc metal-operator-remote-webhook-service metal-operator-metal-registry-service
  run S get ingress metal-operator-metal-registry-ingress
  run S get cm remote-kubeconfig
  run bash -c "echo -n '  networkpolicy count: '; u8s kubectl --context '$SEED_CTX' -n '$CP_NS' get networkpolicy --no-headers 2>/dev/null | wc -l"
  ok "SEED render verified"
  pause

  # ---- SHOOT render verification --------------------------------------------
  step "SHOOT render — refresh shoot kubeconfig, then verify CRDs/RBAC/VWC landed"
  refresh_shoot_kubeconfig || { warn "cannot reach shoot; skipping shoot-render checks"; return; }
  pause

  step "SHOOT render — upstream metal CRDs present"
  run bash -c "echo -n '  metal.ironcore.dev CRD count: '; kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd 2>/dev/null | grep -c metal.ironcore.dev"
  local crdc
  crdc=$(H get crd 2>/dev/null | grep -c metal.ironcore.dev || echo 0)
  expect_ge "${crdc:-0}" 1 "shoot metal CRDs"
  pause

  step "SHOOT render — ValidatingWebhookConfiguration: URL rewritten + injector label"
  run bash -c "kubectl --kubeconfig '$SHOOT_KUBECONFIG' get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o yaml | grep -E 'url:|dual-deployment-operator.cc.sap/webhook-injector' | head"
  local lbl
  lbl=$(H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o jsonpath='{.metadata.labels.dual-deployment-operator\.cc\.sap/webhook-injector}' 2>/dev/null)
  [[ "$lbl" == "metal-operator" ]] && ok "injector label present: $lbl" || warn "injector label = '$lbl' (expected metal-operator)"
  pause

  step "SHOOT render — THE key end-to-end proof: caBundle patched by the injector"
  note "The chart emits the VWC with caBundle UNSET; the operator strips it on apply;"
  note "the webhook-injector sidecar patches it in. A non-empty caBundle proves the"
  note "whole target-patch + label + operator-scoping chain works together."
  local cab
  cab=$(H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o jsonpath='{.webhooks[0].clientConfig.caBundle}' 2>/dev/null | wc -c | tr -d ' ')
  expect_ge "${cab:-0}" 100 "VWC caBundle length (injector stamped it)"
  pause

  step "SHOOT render — RBAC, SA (in $SHOOT_RENDER_NS), oidc-ias bindings, metal-servers ns"
  run H get clusterrole metal-api-viewer metal-operator-dns-records metal-operator-webhook-injector
  run H -n "$SHOOT_RENDER_NS" get sa metal-operator-controller-manager
  run bash -c "echo -n '  cc:oidc-ias clusterrolebindings: '; kubectl --kubeconfig '$SHOOT_KUBECONFIG' get clusterrolebinding 2>/dev/null | grep -c 'cc:oidc-ias' || true"
  run H get ns metal-servers
  ok "SHOOT render verified"
  pause

  step "No-impact check — production metal shoot $PROD_CP_NS untouched"
  run SC -n "$PROD_CP_NS" get deploy metal-operator-controller-manager -o wide \
    || note "(prod CP namespace not visible from this demo context — fine)"
  ok "Phase 2 complete — both renders landed; caBundle proof green."
  pause
}

# =============================================================================
# PHASE 3 — MUTATION / RECONCILE TESTS
# =============================================================================
# The operator prunes/re-renders on the reconcile AFTER the CR change (one-cycle
# lag). We force a reconcile by annotating the CR, then wait for LastReconcile to
# advance before asserting.
force_reconcile() {
  local before after i
  before=$(S get ddo "$CR_NAME" -o jsonpath='{.status.lastReconcile}' 2>/dev/null)
  S annotate ddo "$CR_NAME" "demo.cc.sap/force-reconcile=$(date +%s)" --overwrite >/dev/null 2>&1
  for i in $(seq 1 20); do
    after=$(S get ddo "$CR_NAME" -o jsonpath='{.status.lastReconcile}' 2>/dev/null)
    [[ -n "$after" && "$after" != "$before" ]] && { note "reconcile advanced ($after)"; return 0; }
    sleep 3
  done
  warn "reconcile timestamp did not advance within ~60s (continuing)"
}

phase3_mutations() {
  phase "3" "MUTATIONS — 5 reconcile tests, verifying self-heal after each"
  refresh_shoot_kubeconfig || warn "shoot unreachable; mutation checks that touch the shoot will be limited"

  # ---- Mutation 1: drift correction on the shoot ----------------------------
  step "M1 — DRIFT CORRECTION: delete an operator-applied shoot ClusterRole, expect recreate"
  run H delete clusterrole metal-api-viewer --ignore-not-found
  note "deleted metal-api-viewer on the shoot; forcing a reconcile…"
  force_reconcile
  run H get clusterrole metal-api-viewer -o jsonpath='{.metadata.name}{"\n"}' \
    && ok "M1 PASS — ClusterRole recreated by the operator" \
    || err "M1 FAIL — ClusterRole not recreated"
  pause

  # ---- Mutation 2: caBundle no-clobber --------------------------------------
  step "M2 — caBundle NO-CLOBBER: clear the VWC caBundle, expect injector re-stamps it"
  note "This proves disjoint SSA ownership: operator owns url/labels, injector owns caBundle."
  run H patch validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
    --type=json -p='[{"op":"replace","path":"/webhooks/0/clientConfig/caBundle","value":""}]' || true
  force_reconcile
  sleep 8
  local cab2
  cab2=$(H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o jsonpath='{.webhooks[0].clientConfig.caBundle}' 2>/dev/null | wc -c | tr -d ' ')
  expect_ge "${cab2:-0}" 100 "M2 caBundle re-stamped after operator re-apply"
  pause

  # ---- Mutation 3: macdb self-heal on the seed ------------------------------
  step "M3 — macdb SELF-HEAL: corrupt the resolved macdb Secret, expect re-render + re-resolve"
  run S patch secret macdb --type=merge -p '{"data":{"macdb.yaml":"Z2FyYmFnZQo="}}' || true  # "garbage"
  note "overwrote macdb .data with garbage; forcing a reconcile…"
  force_reconcile
  sleep 8
  local vleft3
  vleft3=$(S get secret macdb -o jsonpath='{.data.macdb\.yaml}' 2>/dev/null | base64 -d 2>/dev/null | grep -c 'vault+kvv2' || echo 0)
  if [[ "${vleft3:-1}" -eq 0 ]]; then ok "M3 PASS — macdb re-applied and re-resolved (0 vault refs)"; else warn "M3 — $vleft3 vault refs (injector may still be resolving; recheck)"; fi
  pause

  # ---- Mutation 4: transform change -----------------------------------------
  step "M4 — TRANSFORM CHANGE: change the injector-label value in the CR, expect new label on shoot VWC"
  note "We patch the CR's patch-transform label to a demo value, verify it lands, then revert."
  run S patch ddo "$CR_NAME" --type=json \
    -p='[{"op":"replace","path":"/spec/transformations/1/patch/strategicMerge/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector","value":"metal-operator-demo"}]' \
    || warn "patch path may differ if transform order changed; inspect spec.transformations"
  force_reconcile
  sleep 6
  run H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
    -o jsonpath='{.metadata.labels.dual-deployment-operator\.cc\.sap/webhook-injector}{"\n"}'
  note "reverting the label back to metal-operator…"
  run S patch ddo "$CR_NAME" --type=json \
    -p='[{"op":"replace","path":"/spec/transformations/1/patch/strategicMerge/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector","value":"metal-operator"}]' || true
  force_reconcile
  ok "M4 done — transform change applied and reverted"
  pause

  # ---- Mutation 5: CR-update re-render + prune ------------------------------
  step "M5 — CR UPDATE re-render/prune: flip dnsRecordTemplate.enabled true→false, expect ConfigMap pruned"
  warn "PRUNE LAGS BY ONE RECONCILE CYCLE — we force a reconcile and wait before asserting."
  run S patch ddo "$CR_NAME" --type=merge \
    -p '{"spec":{"source":{"helm":{"values":{"dnsRecordTemplate":{"enabled":false}}}}}}' || true
  force_reconcile ; force_reconcile   # two cycles: one re-renders, next prunes
  sleep 6
  if S get cm bmc-dns-record-template >/dev/null 2>&1 || S get cm -l "dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}" 2>/dev/null | grep -qi dns; then
    warn "M5 — dns-record ConfigMap still present (may need one more resync; re-run force_reconcile)"
  else
    ok "M5 PASS — dns-record ConfigMap pruned after the CR change"
  fi
  note "reverting dnsRecordTemplate.enabled back to true…"
  run S patch ddo "$CR_NAME" --type=merge \
    -p '{"spec":{"source":{"helm":{"values":{"dnsRecordTemplate":{"enabled":true}}}}}}' || true
  force_reconcile
  ok "Phase 3 complete — mutation/self-heal behavior demonstrated."
  pause
}

# =============================================================================
# PHASE 4 — DELETION TEST
# =============================================================================
phase4_deletion() {
  phase "4" "DELETION — delete the CR, verify clean teardown (no finalizer deadlock)"
  note "The operator authenticates to the shoot as its OWN dedicated applier SA"
  note "(dual-deployment-operator-shoot-applier), NOT the workload SA — so deleting"
  note "the workload render does not deauthenticate the operator. Teardown completes."

  step "Show what exists right before deletion (seed + shoot)"
  run S get deploy metal-operator-controller-manager -o wide || true
  [[ -s "$SHOOT_KUBECONFIG" ]] && run bash -c "kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd | grep -c metal.ironcore.dev || true"
  pause

  step "Delete the DualDeploymentOperator CR (operator runs its finalizer teardown)"
  run bash -c "time u8s kubectl --context '$SEED_CTX' -n '$CP_NS' delete dualdeploymentoperator '$CR_NAME' --wait=true --timeout=180s"
  if S get ddo "$CR_NAME" >/dev/null 2>&1; then
    err "CR still present — finalizer did NOT complete in time. Investigate operator logs:"
    run S logs deploy/"$RELEASE-controller-manager" --tail=40
  else
    ok "CR deleted cleanly — finalizer completed (no self-deauth deadlock)."
  fi
  pause

  step "Verify SEED render is gone"
  run S get deploy metal-operator-controller-manager 2>/dev/null && err "seed workload still present" || ok "seed render removed"
  pause

  step "Verify SHOOT render is gone (RBAC/VWC removed; CRDs RETAINED by design)"
  if refresh_shoot_kubeconfig; then
    run H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration 2>/dev/null \
      && err "VWC still present" || ok "VWC removed"
    run H get clusterrole metal-api-viewer 2>/dev/null \
      && warn "metal-api-viewer still present" || ok "shoot ClusterRoles removed"
    note "CRDs are retained on purpose (retentionPolicy.crds: Retain) — this is expected:"
    run bash -c "echo -n '  metal.ironcore.dev CRDs still present (retained): '; kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd 2>/dev/null | grep -c metal.ironcore.dev || true"
  fi
  ok "Phase 4 complete — deletion verified. Demo finished."
  pause
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  echo
  printf '%s\n' "${MAG}${B}=============================================================================${R}"
  printf '%s\n' "${MAG}${B}  metal-operator-remote-v2 — dual-deployment-operator E2E DEMO${R}"
  printf '%s\n' "${MAG}${B}=============================================================================${R}"
  note "seed=$SEED_CTX  garden=$GARDEN_CTX  shoot=$SHOOT_NAME  CP-ns=$CP_NS"
  note "operator image=$DDO_IMAGE_REPO:$DDO_IMAGE_TAG"
  note "pauses: $([[ $DO_PAUSE -eq 1 ]] && echo ON || echo OFF)   start phase: $FROM_PHASE"

  preflight

  [[ $FROM_PHASE -le 0 ]] && phase0_cleanup
  [[ $FROM_PHASE -le 1 ]] && phase1_install
  [[ $FROM_PHASE -le 2 ]] && phase2_apply_and_verify
  [[ $FROM_PHASE -le 3 ]] && phase3_mutations
  [[ $FROM_PHASE -le 4 ]] && phase4_deletion

  echo
  ok "ALL PHASES COMPLETE."
  note "Cleanup left the operator + CRDs in place if you skipped a full teardown."
  note "To fully reset: re-run with just Phase 0, or delete the test shoot in the dashboard."
  # tidy the short-lived kubeconfig
  [[ -f "$SHOOT_KUBECONFIG" ]] && rm -f "$SHOOT_KUBECONFIG" && note "removed temp shoot kubeconfig"
}

main "$@"
```
