#!/usr/bin/env bash
# Test: ipam-capi-remote profile correctness

set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/../profiles"
CUTOVER_SCRIPT="$SCRIPT_DIR/../cutover-ddo.sh"
PROFILE="$PROFILES_DIR/ipam-capi-remote.env"

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
  
  [[ "$RELEASE" == "ipam-capi-remote" ]] || exit 1
  [[ "$DDO_CR" == "ipam-capi-remote" ]] || exit 1
  [[ "$LEGACY_CHART_DIR" == "system/ipam-capi-remote" ]] || exit 1
  [[ "$ROLLOUT_ORDER" == "40" ]] || exit 1
  [[ "$DEPLOY" == "ipam-capi-controller-manager" ]] || exit 1
  [[ "$CONTROLLER_POD_SELECTOR" == "control-plane=controller-manager,app.kubernetes.io/name=ipam-capi-remote" ]] || exit 1
  [[ "$CRD_GROUPS" == "ipam.cluster.x-k8s.io" ]] || exit 1
  [[ "$NAMESPACE_CASCADE_GATE" == "off" ]] || exit 1
  [[ "$PROTECT_MRS" == "" ]] || exit 1
  [[ "$FREEZE_KINDS_CLUSTER" == "" ]] || exit 1
  [[ "$FREEZE_KINDS_NS" == "globalinclusterippools.ipam.cluster.x-k8s.io" ]] || exit 1
  [[ "$FREEZE_SERVER_STATES" == "0" ]] || exit 1
  [[ "$BASELINE_SNAPSHOT_KINDS_CLUSTER" == "" ]] || exit 1
  [[ "$BASELINE_SNAPSHOT_KINDS_NS" == "globalinclusterippools.ipam.cluster.x-k8s.io" ]] || exit 1
  [[ "$VERIFY_SAMPLE" == "" ]] || exit 1
  [[ "$OWNED_BY_LABEL" == "dual-deployment-operator.cc.sap/owned-by" ]] || exit 1
) || fail "Profile field value mismatch (check each required field)"
pass "All profile fields have correct values"

# Test 3: Assert OPERAND_CHART_DIR is unset/empty (kustomize delivery, not Helm)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ -z "${OPERAND_CHART_DIR:-}" ]] || exit 1
) || fail "OPERAND_CHART_DIR must be unset/empty for kustomize delivery"
pass "OPERAND_CHART_DIR correctly omitted"

# Test 4: Assert load_profile required fields are non-empty
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ -n "$RELEASE" ]] || exit 1
  [[ -n "$DDO_CR" ]] || exit 1
  [[ -n "$DEPLOY" ]] || exit 1
  [[ -n "$CRD_GROUPS" ]] || exit 1
  [[ -n "$NAMESPACE_CASCADE_GATE" ]] || exit 1
  [[ -n "$OWNED_BY_LABEL" ]] || exit 1
) || fail "One or more load_profile REQUIRED fields is empty"
pass "All load_profile required fields are non-empty"

# Test 5: Assert cutover-ddo.sh load_profile fallback resolves ipam-capi-remote
(
  OPERATOR="ipam-capi-remote"
  PROFILES_DIR="$PROFILES_DIR"
  
  # Simulate the two-line fallback logic from load_profile
  profile_file="$PROFILES_DIR/${OPERATOR}-operator-remote.env"
  [[ -f "$profile_file" ]] || profile_file="$PROFILES_DIR/${OPERATOR}.env"
  
  # Assert the resolved file is ipam-capi-remote.env (not the -operator-remote variant)
  basename_resolved="$(basename "$profile_file")"
  [[ "$basename_resolved" == "ipam-capi-remote.env" ]] || exit 1
) || fail "load_profile fallback logic does not resolve ipam-capi-remote correctly"
pass "load_profile fallback resolves --operator ipam-capi-remote correctly"

echo ""
echo "✅ All ipam-capi-remote profile tests passed"
exit 0
