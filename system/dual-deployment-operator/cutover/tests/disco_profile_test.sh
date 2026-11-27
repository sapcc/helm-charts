#!/usr/bin/env bash
# Test: disco-remote profile correctness

set -euo pipefail

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/../profiles"
CUTOVER_SCRIPT="$SCRIPT_DIR/../cutover-ddo.sh"
PROFILE="$PROFILES_DIR/disco-remote.env"

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

  [[ "$RELEASE" == "disco-remote" ]] || exit 1
  [[ "$DDO_CR" == "disco-remote" ]] || exit 1
  [[ "$LEGACY_CHART_DIR" == "system/disco" ]] || exit 1
  [[ "$ROLLOUT_ORDER" == "50" ]] || exit 1
  [[ "$DEPLOY" == "disco-controller-manager" ]] || exit 1
  [[ "$CONTROLLER_POD_SELECTOR" == "app=disco" ]] || exit 1
  [[ "$CRD_GROUPS" == "disco.stable.sap.cc" ]] || exit 1
  [[ "$CRD_MRS" == "disco-remote-crd" ]] || exit 1
  [[ "$NAMESPACE_CASCADE_GATE" == "off" ]] || exit 1
  [[ "$PROTECT_MRS" == "" ]] || exit 1
  [[ "$FREEZE_KINDS_CLUSTER" == "" ]] || exit 1
  [[ "$FREEZE_KINDS_NS" == "records.disco.stable.sap.cc" ]] || exit 1
  [[ "$FREEZE_SERVER_STATES" == "0" ]] || exit 1
  [[ "$BASELINE_SNAPSHOT_KINDS_CLUSTER" == "" ]] || exit 1
  [[ "$BASELINE_SNAPSHOT_KINDS_NS" == "records.disco.stable.sap.cc" ]] || exit 1
  [[ "$VERIFY_SAMPLE" == "" ]] || exit 1
  [[ "$OWNED_BY_LABEL" == "dual-deployment-operator.cc.sap/owned-by" ]] || exit 1
) || fail "Profile field value mismatch (check each required field)"
pass "All profile fields have correct values"

# Test 3: Assert OPERAND_CHART_DIR is set (disco is Helm-chart-sourced, unlike kustomize ipam)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ "${OPERAND_CHART_DIR:-}" == "system/disco-ddo" ]] || exit 1
) || fail "OPERAND_CHART_DIR must be system/disco-ddo for Helm-chart delivery"
pass "OPERAND_CHART_DIR correctly set to system/disco-ddo"

# Test 4: Assert CRD_MRS is set (disco's legacy chart hand-writes disco-remote-crd,
#         NOT the mr-crd-* naming convention the other four profiles rely on)
(
  # shellcheck source=/dev/null
  source "$PROFILE"
  [[ -n "${CRD_MRS:-}" ]] || exit 1
  [[ "$CRD_MRS" == "disco-remote-crd" ]] || exit 1
) || fail "CRD_MRS must explicitly name disco-remote-crd (legacy non-mr-crd naming)"
pass "CRD_MRS correctly names the explicit legacy CRD ManagedResource"

# Test 5: Assert load_profile required fields are non-empty
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

# Test 6: Assert cutover-ddo.sh load_profile fallback resolves disco-remote
(
  OPERATOR="disco-remote"
  PROFILES_DIR="$PROFILES_DIR"

  # Simulate the two-line fallback logic from load_profile
  profile_file="$PROFILES_DIR/${OPERATOR}-operator-remote.env"
  [[ -f "$profile_file" ]] || profile_file="$PROFILES_DIR/${OPERATOR}.env"

  # Assert the resolved file is disco-remote.env (not the -operator-remote variant)
  basename_resolved="$(basename "$profile_file")"
  [[ "$basename_resolved" == "disco-remote.env" ]] || exit 1
) || fail "load_profile fallback logic does not resolve disco-remote correctly"
pass "load_profile fallback resolves --operator disco-remote correctly"

echo ""
echo "✅ All disco-remote profile tests passed"
exit 0
