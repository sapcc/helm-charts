#!/usr/bin/env bash
# Test: kube-state-metrics-remote profile correctness

set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/../profiles"
CUTOVER_SCRIPT="$SCRIPT_DIR/../cutover-ddo.sh"
PROFILE="$PROFILES_DIR/kube-state-metrics-remote.env"

fail() {
  echo "❌ FAIL: $*" >&2
  exit 1
}

pass() {
  echo "✅ PASS: $*"
}

# Test 1: Profile file exists
[[ -f "$PROFILE" ]] || fail "Profile file not found: $PROFILE"
pass "Profile file exists"

# Test 2: Source profile and check required exact values
(
  # shellcheck source=/dev/null
  source "$PROFILE"

  [[ "$RELEASE" == "kube-state-metrics-remote" ]] || exit 1
  [[ "$DDO_CR" == "kube-state-metrics-remote" ]] || exit 1
  [[ "$LEGACY_CHART_DIR" == "system/kube-state-metrics-remote" ]] || exit 1
  [[ "$ROLLOUT_ORDER" == "60" ]] || exit 1
  [[ "$DEPLOY" == "kube-state-metrics-remote" ]] || exit 1
  [[ "$CONTROLLER_POD_SELECTOR" == "app.kubernetes.io/name=kube-state-metrics-remote" ]] || exit 1
  [[ "$NO_CRDS" == "1" ]] || exit 1
  [[ "${CRD_GROUPS:-}" == "" ]] || exit 1
  [[ "${CRD_MRS:-}" == "" ]] || exit 1
  [[ "$NAMESPACE_CASCADE_GATE" == "off" ]] || exit 1
  [[ "${PROTECT_MRS:-}" == "" ]] || exit 1
  [[ "${FREEZE_KINDS_CLUSTER:-}" == "" ]] || exit 1
  [[ "${FREEZE_KINDS_NS:-}" == "" ]] || exit 1
  [[ "$FREEZE_SERVER_STATES" == "0" ]] || exit 1
  [[ "${BASELINE_SNAPSHOT_KINDS_CLUSTER:-}" == "" ]] || exit 1
  [[ "${BASELINE_SNAPSHOT_KINDS_NS:-}" == "" ]] || exit 1
  [[ "${VERIFY_SAMPLE:-}" == "" ]] || exit 1
  [[ "$OWNED_BY_LABEL" == "dual-deployment-operator.cc.sap/owned-by" ]] || exit 1
) || fail "Profile field value mismatch (check each required field)"
pass "All profile fields have correct values"

# Test 3: NO_CRDS=1 and both CRD_GROUPS/CRD_MRS must be empty (engine invariant)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ "${NO_CRDS:-}" == "1" ]] || exit 1
  [[ -z "${CRD_GROUPS:-}" ]] || exit 1
  [[ -z "${CRD_MRS:-}" ]] || exit 1
) || fail "NO_CRDS=1 profile must have empty CRD_GROUPS and CRD_MRS"
pass "NO_CRDS=1 set with CRD_GROUPS='' and CRD_MRS='' (no ambiguity)"

# Test 4: OPERAND_CHART_DIR correctly set (Helm chart delivery)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ "${OPERAND_CHART_DIR:-}" == "system/kube-state-metrics-remote-ddo" ]] || exit 1
) || fail "OPERAND_CHART_DIR must be system/kube-state-metrics-remote-ddo for Helm-chart delivery"
pass "OPERAND_CHART_DIR correctly set to system/kube-state-metrics-remote-ddo"

# Test 5: Assert load_profile required fields are non-empty (minus CRD_GROUPS which
#         is deliberately empty; load_profile skips the CRD_GROUPS check for NO_CRDS=1)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ -n "$RELEASE" ]] || exit 1
  [[ -n "$DDO_CR" ]] || exit 1
  [[ -n "$DEPLOY" ]] || exit 1
  [[ -n "$NAMESPACE_CASCADE_GATE" ]] || exit 1
  [[ -n "$OWNED_BY_LABEL" ]] || exit 1
) || fail "One or more load_profile REQUIRED fields is empty"
pass "All load_profile required fields are non-empty"

# Test 6: load_profile correctly accepts this profile (NO_CRDS guards the CRD_GROUPS check)
#         Source cutover-ddo.sh then set OPERATOR (script resets it on source)
(
  # shellcheck source=/dev/null
  source "$CUTOVER_SCRIPT"
  # Set required globals AFTER sourcing (the script resets OPERATOR="" at top-level)
  OPERATOR="kube-state-metrics-remote"
  CLUSTER="test"; TARGET_CTX="test"; SEED_CTX="seed"; NAMESPACE="cp"
  PHASE="uninstall"; DRY_RUN=true; RESUME=false; OUTAGE_BUDGET_MIN=20
  load_profile
  # If we reach here without dying, the profile loaded successfully
  [[ "$NO_CRDS" == "1" ]] || exit 1
  [[ -z "${CRD_GROUPS:-}" ]] || exit 1
) || fail "load_profile should accept NO_CRDS=1 profile without dying on empty CRD_GROUPS"
pass "load_profile accepts kube-state-metrics-remote profile (NO_CRDS=1 guards CRD_GROUPS check)"

# Test 7: Assert load_profile fallback resolves kube-state-metrics-remote
#         (exact-name .env, same as disco-remote.env pattern)
(
  OPERATOR="kube-state-metrics-remote"
  _profiles_dir="$PROFILES_DIR"

  # Simulate the two-line fallback logic from load_profile
  profile_file="${_profiles_dir}/${OPERATOR}-operator-remote.env"
  [[ -f "$profile_file" ]] || profile_file="${_profiles_dir}/${OPERATOR}.env"

  # Assert the resolved file is kube-state-metrics-remote.env
  basename_resolved="$(basename "$profile_file")"
  [[ "$basename_resolved" == "kube-state-metrics-remote.env" ]] || exit 1
) || fail "load_profile fallback logic does not resolve kube-state-metrics-remote correctly"
pass "load_profile fallback resolves --operator kube-state-metrics-remote correctly"

echo ""
echo "✅ All kube-state-metrics-remote profile tests passed"
exit 0
