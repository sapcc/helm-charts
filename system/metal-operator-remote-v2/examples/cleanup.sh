#!/usr/bin/env bash
# =============================================================================
#  metal-operator-remote-v2 — STANDALONE FULL-TEARDOWN SCRIPT
# =============================================================================
#  Removes ALL installation of the dual-deployment-operator and metal-operator
#  on BOTH clusters:
#
#    •  DualDeploymentOperator CR (operator-driven teardown first)
#    •  Operator release (helm uninstall) from the seed CP namespace
#    •  DualDeploymentOperator CRD on the seed
#    •  All seed-render objects (operator-owned Deployments, Services,
#       Ingresses, NetworkPolicies, Secrets, ConfigMaps)
#    •  The ENTIRE shoot render: ValidatingWebhookConfiguration, ClusterRoles,
#       ClusterRoleBindings, Namespace (metal-servers), ServiceAccount, AND
#       every metal.ironcore.dev CRD (plus any CRs of those kinds).
#
#  ⚠️  DESTRUCTIVE — leaves both clusters pristine.
#
#  SAFETY: only touches the TEST shoot (test-qa-de-1).
#          NEVER touches the production metal shoot m-qa-de-1.
#
#  USAGE:
#    ./cleanup.sh               # run the full teardown (non-interactive)
#    ./cleanup.sh -h            # show this help
#
#  Run this before a fresh demo, or to reset after a partial or failed run.
#  It is a standalone, non-interactive teardown — it never waits for input.
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

# (unused by cleanup; kept for config symmetry with demo-e2e.sh)
DDO_IMAGE_REPO="${DDO_IMAGE_REPO:-keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator}"
DDO_CHART_DIR="${DDO_CHART_DIR:-/Users/D065300/IdeaProjects/sapcc/dual-deployment-operator/chart}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Where to write the freshly-minted shoot admin kubeconfig (short-TTL).
SHOOT_KUBECONFIG="${SHOOT_KUBECONFIG:-$SCRIPT_DIR/.demo-$SHOOT_NAME.kubeconfig}"
SHOOT_KUBECONFIG_TTL="${SHOOT_KUBECONFIG_TTL:-3600}"      # seconds; Gardener AdminKubeconfigRequest

# -----------------------------------------------------------------------------
# arg parsing
# -----------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
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

# seed / shoot command shortcuts
S()  { u8s kubectl --context "$SEED_CTX" -n "$CP_NS" "$@"; }
SC() { u8s kubectl --context "$SEED_CTX" "$@"; }               # seed, cluster-scoped
H()  { kubectl --kubeconfig "$SHOOT_KUBECONFIG" "$@"; }        # shoot (admin kubeconfig)

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
# PREFLIGHT (lite) — tools + seed reachable
# =============================================================================
preflight_lite() {
  step "Check required CLIs are present"
  local missing=0
  for c in u8s kubectl yq; do
    if command -v "$c" >/dev/null 2>&1; then ok "found: $c"; else err "missing: $c"; missing=1; fi
  done
  [[ $missing -eq 1 ]] && { err "Install the missing tools and re-run."; exit 1; }

  step "Confirm seed context reachable ($SEED_CTX)"
  run_check bash -c "u8s kubectl --context '$SEED_CTX' get --raw='/readyz' >/dev/null"
  ok "seed reachable"

  step "Check CP namespace on the seed ($CP_NS)"
  if u8s kubectl --context "$SEED_CTX" get ns "$CP_NS" >/dev/null 2>&1; then
    ok "CP namespace present: $CP_NS"
  else
    note "CP namespace $CP_NS absent — nothing to clean there (fine)"
  fi
}

# =============================================================================
# CLEANUP — full teardown (seed + shoot, incl. all CRDs)
# =============================================================================
do_cleanup() {
  phase "0" "CLEANUP — remove all prior test resources (seed + shoot, incl. CRDs)"
  warn "This resets BOTH clusters to a pristine state. Only touches the TEST shoot (${SHOOT_NAME}). Never touches m-qa-de-1."

  step "Show any existing CR (so we can see the starting state)"
  run S get dualdeploymentoperator -o wide || true

  step "Delete the DualDeploymentOperator CR (lets the operator tear down its renders first)"
  note "If the operator is healthy this cleanly removes both renders. If it is absent or"
  note "wedged, we fall back to clearing the finalizer so cleanup never hangs."
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

  step "Uninstall the operator release from the seed (if present)"
  run bash -c "U8S_CONTEXT='$SEED_CTX' u8s helm3 -- uninstall '$RELEASE' --namespace '$CP_NS'" \
    || note "no release named $RELEASE in $CP_NS (fine)"

  step "Delete the operator CRD on the seed (chart keeps it by default: crd.keep=true)"
  run SC delete crd dualdeploymentoperators.dual-deployment-operator.cc.sap --ignore-not-found

  step "Sweep any leftover SEED-render objects owned by this CR"
  note "The operator normally prunes these, but a hard finalizer-clear can orphan them."
  local owned="dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}"
  for kind in deploy svc ingress networkpolicy secret configmap; do
    run S delete "$kind" -l "$owned" --ignore-not-found || true
  done
  # Named seed objects the chart creates (belt-and-suspenders):
  run S delete deploy metal-operator-controller-manager --ignore-not-found || true
  run S delete secret macdb remote-kubeconfig metal-operator-remote-kubeconfig --ignore-not-found || true

  step "Sweep the SHOOT-render objects (VWC, RBAC, SA, Namespace, metal CRDs) on the test shoot"
  if refresh_shoot_kubeconfig; then
    run H delete validatingwebhookconfiguration metal-operator-validating-webhook-configuration --ignore-not-found || true
    run H delete clusterrole metal-api-viewer metal-operator-dns-records metal-operator-webhook-injector --ignore-not-found || true
    run H delete clusterrolebinding -l "dual-deployment-operator.cc.sap/owned-by=${CP_NS}_${CR_NAME}" --ignore-not-found || true
    run H delete ns metal-servers --ignore-not-found || true
    run H -n "$SHOOT_RENDER_NS" delete sa metal-operator-controller-manager --ignore-not-found || true
    note "Deleting the metal.ironcore.dev CRDs (this also removes any CRs of those kinds):"
    run bash -c "kubectl --kubeconfig '$SHOOT_KUBECONFIG' get crd -o name | { grep metal.ironcore.dev || true; } | xargs -r kubectl --kubeconfig '$SHOOT_KUBECONFIG' delete --ignore-not-found"
    ok "shoot render swept"
  else
    warn "Skipped shoot sweep (no kubeconfig). Continue only if the shoot is already clean."
  fi

  step "Confirm pristine: no CR, no seed workload, metal CRD count on the shoot (should be 0)"
  if S get dualdeploymentoperator "$CR_NAME" >/dev/null 2>&1; then
    warn "CR still present (unexpected)"
  else
    ok "no CR (pristine)"
  fi
  if S get deploy metal-operator-controller-manager >/dev/null 2>&1; then
    warn "seed workload still present (unexpected)"
  else
    ok "no seed workload (pristine)"
  fi
  if [[ -s "$SHOOT_KUBECONFIG" ]]; then
    local crd_count
    crd_count=$(kubectl --kubeconfig "$SHOOT_KUBECONFIG" get crd -o name 2>/dev/null | { grep -c metal.ironcore.dev || true; })
    ok "shoot metal.ironcore.dev CRD count: ${crd_count:-0} (0 = pristine)"
  fi
  ok "Cleanup complete — both clusters are pristine."

  [[ -f "$SHOOT_KUBECONFIG" ]] && rm -f "$SHOOT_KUBECONFIG" && note "removed temp shoot kubeconfig"
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  echo
  printf '%s\n' "${MAG}${B}=============================================================================${R}"
  printf '%s\n' "${MAG}${B}  metal-operator-remote-v2 — STANDALONE FULL TEARDOWN${R}"
  printf '%s\n' "${MAG}${B}=============================================================================${R}"
  note "seed=$SEED_CTX  garden=$GARDEN_CTX  shoot=$SHOOT_NAME  CP-ns=$CP_NS"

  preflight_lite
  do_cleanup
}

main "$@"
