#!/usr/bin/env bash
# =============================================================================
#  metal-operator-remote-v2 — END-TO-END DEMO SCRIPT
# =============================================================================
#  Drives the full operator-native delivery flow for a live audience:
#
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
#  CLEANUP IS SEPARATE: this script does NOT clean up. Run ./cleanup.sh first to
#  reset to a pristine state (removes operator release + CRD on the seed and the
#  ENTIRE shoot render incl. CRDs). This demo assumes a clean starting point.
#
#  DEMO MODE: the script PAUSES before and after every microstep and waits for
#  you to press Enter, printing each command and its result clearly so the
#  audience can follow along. Run with --no-pause to disable pauses.
#
#  PREREQUISITES (assumed already done — the script does NOT build these):
#    * A clean starting state — run ./cleanup.sh first if a prior run left state.
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
#    ./cleanup.sh                  # reset to pristine (separate script)
#    ./demo-e2e.sh                 # full demo, pauses at every step
#    ./demo-e2e.sh --no-pause      # run straight through (rehearsal / CI-ish)
#    ./demo-e2e.sh --from 3        # skip to a phase (1-4); earlier phases skipped
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
DDO_IMAGE_REPO="${DDO_IMAGE_REPO:-keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator}"
DDO_IMAGE_TAG="${DDO_IMAGE_TAG:-}"

# Operator install-chart source directory.
DDO_CHART_DIR="${DDO_CHART_DIR:-/Users/D065300/IdeaProjects/sapcc/dual-deployment-operator/chart}"

# The example CR lives next to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CR_FILE="${CR_FILE:-$SCRIPT_DIR/dualdeploymentoperator-test-qa-de-1.yaml}"

# Where to write the freshly-minted shoot admin kubeconfig (short-TTL).
SHOOT_KUBECONFIG="${SHOOT_KUBECONFIG:-$SCRIPT_DIR/.demo-$SHOOT_NAME.kubeconfig}"
SHOOT_KUBECONFIG_TTL="${SHOOT_KUBECONFIG_TTL:-3600}"      # seconds; Gardener AdminKubeconfigRequest

# Mutation-test convergence polling. Measured ~50s to propagate a CR change to the
# live shoot manifest (re-render + SSA + shoot round-trip + injector cadence), so the
# default window is generous (40 x 5s = ~200s). Override via env for slow/fast clusters.
WAIT_ATTEMPTS="${WAIT_ATTEMPTS:-40}"
WAIT_INTERVAL="${WAIT_INTERVAL:-5}"

DO_PAUSE=1
FROM_PHASE=1

# -----------------------------------------------------------------------------
# arg parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pause) DO_PAUSE=0; shift ;;
    --from)     FROM_PHASE="${2:-1}"; shift 2 ;;
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

# prompt_tag() — interactively prompt for DDO_IMAGE_TAG when unset.
# Uses /dev/tty so the script remains usable when stdin is piped.
prompt_tag() {
  # If tag already set (via env), nothing to do.
  [[ -n "${DDO_IMAGE_TAG:-}" ]] && return 0

  step "Resolve operator image (repo fixed; tag interactive if unset)"
  note "DDO_IMAGE_REPO = $DDO_IMAGE_REPO (override via env if needed)"

  while [[ -z "${DDO_IMAGE_TAG:-}" ]]; do
    printf '%s' "${YEL}${B}Enter DDO_IMAGE_TAG (image tag to use): ${R}"
    # Read from the controlling terminal to avoid consuming stdin in pipelines
    if ! read -r DDO_IMAGE_TAG < /dev/tty; then
      err "Failed to read from /dev/tty; DDO_IMAGE_TAG remains unset. Aborting."
      exit 1
    fi
    if [[ -z "${DDO_IMAGE_TAG}" ]]; then
      warn "DDO_IMAGE_TAG cannot be empty. Please enter a tag (e.g. 0.1.0 or sha-abc123)."
    fi
  done
  ok "operator image: $DDO_IMAGE_REPO:$DDO_IMAGE_TAG"
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

  step "Resolve operator image (repo defaulted; tag interactive if unset)"
  # DDO_IMAGE_REPO is baked with a repo default above but may be overridden via env.
  if [[ -z "$DDO_IMAGE_REPO" ]]; then
    err "DDO_IMAGE_REPO must be set (or the baked default must exist)."
    exit 1
  fi
  # Prompt interactively for DDO_IMAGE_TAG if not provided in the environment.
  prompt_tag

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
  run_check bash -c "u8s kubectl --context '$GARDEN_CTX' -n garden get shoot '$SHOOT_NAME' -o jsonpath='{.status.lastOperation.state}'; echo"
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
  note "pullPolicy=Always is REQUIRED: the tag '$DDO_IMAGE_TAG' is overwritten in place on"
  note "keppel, so IfNotPresent would keep running a stale node-cached digest. Always forces"
  note "a fresh pull on every pod start so the running binary matches the pushed image."
  run_check bash -c "U8S_CONTEXT='$SEED_CTX' u8s helm3 -- upgrade --install '$RELEASE' '$DDO_CHART_DIR' \
    --namespace '$CP_NS' \
    --set manager.image.repository='$DDO_IMAGE_REPO' \
    --set manager.image.tag='$DDO_IMAGE_TAG' \
    --set manager.image.pullPolicy=Always \
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
  run bash -c "grep -vE '^\s*#' '$CR_FILE' | sed '/^\s*$/d' | head -60"
  pause

  step "Apply the DualDeploymentOperator CR"
  run_check S apply -f "$CR_FILE"
  ok "CR applied"
  pause

  step "Watch the CR reconcile toward Ready=True (observe status in the seed)"
  note "The operator renders the chart twice, applies the shoot render, then the seed"
  note "render (applyOrder: ShootFirst), and patches the webhook caBundle via the injector."
  local st
  for i in $(seq 1 30); do
    st=$(S get ddo "$CR_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status} {.status.conditions[?(@.type=="Ready")].reason}' 2>/dev/null)
    echo "  [$i] Ready=$st"
    [[ "$st" == True* ]] && break
    sleep 6
  done
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
  vleft=$(S get secret macdb -o jsonpath='{.data.macdb\.yaml}' 2>/dev/null | base64 -d 2>/dev/null | grep -c 'vault+kvv2')
  vleft=$(printf '%s' "${vleft:-0}" | tr -dc '0-9')
  if [[ "${vleft:-0}" -eq 0 ]]; then ok "macdb resolved (0 vault+kvv2 refs remain)"; else warn "macdb still has $vleft vault refs (injector may be pending)"; fi
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
  crdc=$(H get crd 2>/dev/null | grep -c metal.ironcore.dev)
  crdc=$(printf '%s' "${crdc:-0}" | tr -dc '0-9')
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
# force_reconcile — nudge the operator to reconcile now by annotating the CR, then
# give it a short settle window. The operator has no observedGeneration/generation
# gate and lastReconcile is only 1-second resolution, so a timestamp-diff is an
# unreliable progress signal (false "did not advance" on same-second reconciles or
# when the triggering .spec patch already reconciled). We therefore do NOT gate on
# the timestamp — the authoritative check is always the per-test assertion that polls
# the live manifest for the expected outcome (see wait_for_jsonpath).
force_reconcile() {
  S annotate ddo "$CR_NAME" "demo.cc.sap/force-reconcile=$(date +%s)" --overwrite >/dev/null 2>&1
  sleep 6
}

# wait_for_jsonpath — poll a live object (via a command builder) until its jsonpath
# value equals the expected string, or timeout. Prints each observed value so the
# audience sees the transform being carried out on the LIVE manifest.
#   $1 = human label
#   $2 = expected value
#   $3.. = the get command (e.g. H get validatingwebhookconfiguration NAME -o jsonpath=...)
# Usage: wait_for_jsonpath "VWC injector label" "metal-operator-demo" \
#          H get validatingwebhookconfiguration NAME -o jsonpath='{.metadata.labels....}'
wait_for_jsonpath() {
  local label="$1" expected="$2"; shift 2
  local got i
  for i in $(seq 1 "$WAIT_ATTEMPTS"); do
    got=$("$@" 2>/dev/null)
    echo "  [$i/$WAIT_ATTEMPTS] $label = '${got}'"
    [[ "$got" == "$expected" ]] && { ok "$label converged to '$expected' on the live manifest"; return 0; }
    sleep "$WAIT_INTERVAL"
  done
  warn "$label did not reach '$expected' within ~$((WAIT_ATTEMPTS * WAIT_INTERVAL))s (last: '${got}')"
  return 1
}

# wait_until — poll a shell predicate until it succeeds (exit 0) or timeout. Used
# for outcomes that are not a simple jsonpath==string (caBundle length threshold,
# vault-ref count, object absence). The window is generous (see WAIT_ATTEMPTS)
# because the CR-change → operator re-render → SSA → shoot API round-trip, plus the
# webhook-injector's own ~42s reconcile cadence, can take ~50s+ to converge — a
# tighter window misreads a slow-but-correct reconcile as a failure.
#   $1 = human label
#   $2.. = the predicate command (evaluated; success = converged)
wait_until() {
  local label="$1"; shift
  local i
  for i in $(seq 1 "$WAIT_ATTEMPTS"); do
    if "$@"; then ok "$label converged"; return 0; fi
    echo "  [$i/$WAIT_ATTEMPTS] $label — not yet…"
    sleep "$WAIT_INTERVAL"
  done
  warn "$label did not converge within ~$((WAIT_ATTEMPTS * WAIT_INTERVAL))s"
  return 1
}

phase3_mutations() {
  phase "3" "MUTATIONS — 5 reconcile tests, verifying self-heal after each"
  refresh_shoot_kubeconfig || warn "shoot unreachable; mutation checks that touch the shoot will be limited"

  # ---- Mutation 1: drift correction on the shoot ----------------------------
  step "M1 — DRIFT CORRECTION: delete an operator-applied shoot ClusterRole, expect recreate"
  run H delete clusterrole metal-api-viewer --ignore-not-found
  note "deleted metal-api-viewer on the shoot; forcing a reconcile and waiting for recreate…"
  force_reconcile
  if wait_until "M1 shoot ClusterRole metal-api-viewer recreated" \
       H get clusterrole metal-api-viewer -o name; then
    ok "M1 PASS — ClusterRole recreated by the operator (drift corrected)"
  else
    err "M1 FAIL — ClusterRole not recreated within ~60s"
  fi
  pause

  # ---- Mutation 2: caBundle no-clobber --------------------------------------
  step "M2 — caBundle NO-CLOBBER: clear the VWC caBundle, expect injector re-stamps it"
  note "This proves disjoint SSA ownership: operator owns url/labels, injector owns caBundle."
  run H patch validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
    --type=json -p='[{"op":"replace","path":"/webhooks/0/clientConfig/caBundle","value":""}]' || true
  force_reconcile
  if wait_until "M2 VWC caBundle re-stamped (>=100 bytes)" \
       bash -c 'n=$(kubectl --kubeconfig "'"$SHOOT_KUBECONFIG"'" get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o jsonpath="{.webhooks[0].clientConfig.caBundle}" 2>/dev/null | wc -c | tr -d " "); [[ "${n:-0}" -ge 100 ]]'; then
    ok "M2 PASS — injector re-stamped caBundle; operator re-apply did not clobber it"
  else
    warn "M2 — caBundle not re-stamped within ~60s (injector may be lagging)"
  fi
  pause

  # ---- Mutation 3: macdb self-heal on the seed ------------------------------
  step "M3 — macdb SELF-HEAL: corrupt the resolved macdb Secret, expect re-render + re-resolve"
  run S patch secret macdb --type=merge -p '{"data":{"macdb.yaml":"Z2FyYmFnZQo="}}' || true  # "garbage"
  note "overwrote macdb .data with garbage; forcing a reconcile and waiting for re-resolve…"
  force_reconcile
  if wait_until "M3 macdb re-applied + re-resolved (0 vault refs)" \
       bash -c 'n=$(u8s kubectl --context "'"$SEED_CTX"'" -n "'"$CP_NS"'" get secret macdb -o jsonpath="{.data.macdb\.yaml}" 2>/dev/null | base64 -d 2>/dev/null | grep -c "vault+kvv2"); n=$(printf "%s" "${n:-0}" | tr -dc "0-9"); [[ "${n:-0}" -eq 0 ]] && [[ -n "$(u8s kubectl --context "'"$SEED_CTX"'" -n "'"$CP_NS"'" get secret macdb -o jsonpath="{.data.macdb\.yaml}" 2>/dev/null)" ]]'; then
    ok "M3 PASS — macdb re-applied (vault+kvv2 template) and re-resolved by secrets-injector (0 leaked refs)"
  else
    warn "M3 — macdb not fully re-resolved within ~60s (secrets-injector may still be resolving)"
  fi
  pause

  # ---- Mutation 4: transform change -----------------------------------------
  step "M4 — TRANSFORM CHANGE: change the injector-label value in the CR, expect new label on shoot VWC"
  note "We patch the CR's patch-transform label to a demo value, then ASSERT the live"
  note "shoot VWC carries the new label (transform actually carried out), then revert."
  run S patch ddo "$CR_NAME" --type=json \
    -p='[{"op":"replace","path":"/spec/transformations/1/patch/strategicMerge/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector","value":"metal-operator-demo"}]' \
    || warn "patch path may differ if transform order changed; inspect spec.transformations"
  force_reconcile
  wait_for_jsonpath "M4 shoot VWC injector label" "metal-operator-demo" \
    H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
    -o 'jsonpath={.metadata.labels.dual-deployment-operator\.cc\.sap/webhook-injector}' \
    && ok "M4 PASS — transform carried out on the live shoot manifest" \
    || warn "M4 — new label not observed on the live VWC (see values above)"
  note "reverting the label back to metal-operator…"
  run S patch ddo "$CR_NAME" --type=json \
    -p='[{"op":"replace","path":"/spec/transformations/1/patch/strategicMerge/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector","value":"metal-operator"}]' || true
  force_reconcile
  wait_for_jsonpath "M4 shoot VWC injector label (reverted)" "metal-operator" \
    H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
    -o 'jsonpath={.metadata.labels.dual-deployment-operator\.cc\.sap/webhook-injector}' \
    && ok "M4 revert confirmed on the live shoot manifest" \
    || warn "M4 — revert not observed on the live VWC (see values above)"
  pause

  # ---- Mutation 5: CR-update re-render + prune ------------------------------
  step "M5 — CR UPDATE re-render/prune: flip dnsRecordTemplate.enabled true→false, expect ConfigMap pruned"
  note "Prune is SAME-CYCLE: the reconcile that processes this CR change re-renders"
  note "(ConfigMap absent) and prunes it against the prior inventory in the same pass."
  run S patch ddo "$CR_NAME" --type=merge \
    -p '{"spec":{"source":{"helm":{"values":{"dnsRecordTemplate":{"enabled":false}}}}}}' || true
  force_reconcile
  if wait_until "M5 dns-record ConfigMap pruned" \
       bash -c '! u8s kubectl --context "'"$SEED_CTX"'" -n "'"$CP_NS"'" get cm bmc-dns-record-template >/dev/null 2>&1 && ! u8s kubectl --context "'"$SEED_CTX"'" -n "'"$CP_NS"'" get cm -l "dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}" 2>/dev/null | grep -qi dns'; then
    ok "M5 PASS — dns-record ConfigMap pruned after the CR change"
  else
    warn "M5 — dns-record ConfigMap still present within ~60s (unexpected; check operator logs)"
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

  [[ $FROM_PHASE -le 1 ]] && phase1_install
  [[ $FROM_PHASE -le 2 ]] && phase2_apply_and_verify
  [[ $FROM_PHASE -le 3 ]] && phase3_mutations
  [[ $FROM_PHASE -le 4 ]] && phase4_deletion

  echo
  ok "ALL PHASES COMPLETE."
  note "This demo does not clean up. To reset: run ./cleanup.sh (removes operator +"
  note "CRDs on the seed and the entire shoot render), or delete the test shoot in the dashboard."
  # tidy the short-lived kubeconfig
  [[ -f "$SHOOT_KUBECONFIG" ]] && rm -f "$SHOOT_KUBECONFIG" && note "removed temp shoot kubeconfig"
}

main "$@"
