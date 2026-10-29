#!/usr/bin/env bash
# cutover-ddo.sh — Generalized DDO cutover engine (Layer 2)
#
# Usage: cutover-ddo.sh --operator <metal|boot> --phase <uninstall|verify> \
#          --cluster <shoot> [options]
#
# This script implements the full cutover lifecycle for migrating a Gardener
# extension operator to DualDeploymentOperator management. It is parameterized
# by operator-specific profiles under profiles/<operator>-operator-remote.env.
#
# SAFETY DISCIPLINE: This script is fail-closed throughout. Any read error
# (connectivity, auth, transient API failure) is treated as "unknown state"
# and blocks rather than proceeds. The three-state rollback planner (S0-S3)
# never guesses when state is unreadable.
#
# Exit codes:
#   0  - Success
#   2  - Abort (user error, confirmation mismatch, blocked by gate)
#   20 - Uninstall complete, proceed to merge CR PR (not an error)
#   30 - Outage budget blown, rollback required
set -Eeuo pipefail
# Named ERR handler, reused so obj_state can restore the exact same trap after
# temporarily clearing it for its guarded (expected-to-fail) read.
err_trap() { printf "\nERROR: line %s: command failed: %s\n" "$1" "$2" >&2; }
trap 'err_trap "$LINENO" "$BASH_COMMAND"' ERR

# ============================================================================
# CLI argument defaults
# ============================================================================
OPERATOR=""
CLUSTER=""
TARGET_CTX=""
SEED_CTX=""
NAMESPACE=""
PHASE=""
DRY_RUN=false
OUTAGE_BUDGET_MIN="${OUTAGE_BUDGET_MIN:-20}"
SKIP_PREREQ_CHECK=false
FRESH_DELETE_MIN="${FRESH_DELETE_MIN:-2880}"  # 48 hours
PROBE_TIMEOUT="${PROBE_TIMEOUT:-8s}"

# ============================================================================
# Output helpers
# ============================================================================
die()  { printf 'ABORT: %s\n' "$*" >&2; exit 2; }
info() { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
step() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$*"; }

# ============================================================================
# Argument parsing
# ============================================================================
usage() {
  cat <<EOF
Usage: $(basename "$0") --operator <name> --phase <uninstall|verify> \\
         --cluster <shoot> [options]

Required:
  --operator <name>       Operator profile (metal, boot)
  --phase <phase>         Phase to execute (uninstall, verify)
  --cluster <shoot>       Shoot cluster name (e.g. m-qa-de-200)

Optional:
  --target-context <ctx>  kubectl context for the target/shoot cluster
                          (default: --cluster)
  --namespace <ns>        Seed control-plane namespace
                          (default: shoot--cp--<shoot>)
  --seed-context <ctx>    kubectl context for the seed cluster
                          (auto-discovered from --cluster/--namespace if omitted)
  --release <name>        Helm release name (default: from profile)
  --ddo-cr <name>         DualDeploymentOperator CR name (default: from profile)
  --deploy <name>         Controller Deployment name (default: from profile)
  --dry-run               Show what would be done without making changes
  --outage-budget <min>   Minutes allowed for cutover (default: 20)
  --skip-prereq-check     Skip DDO prerequisite checks (use with caution)
  --help                  Show this help

Exit codes:
  0   Success
  2   Abort (user error, gate blocked, confirmation mismatch)
  20  Uninstall complete — proceed to merge the CR PR
  30  Outage budget blown — rollback required
EOF
  exit "${1:-0}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --operator)      OPERATOR="$2"; shift 2 ;;
      --cluster)       CLUSTER="$2"; shift 2 ;;
      --target-context) TARGET_CTX="$2"; shift 2 ;;
      --seed-context)  SEED_CTX="$2"; shift 2 ;;
      --namespace)     NAMESPACE="$2"; shift 2 ;;
      --release)       RELEASE_OVERRIDE="$2"; shift 2 ;;
      --ddo-cr)        DDO_CR_OVERRIDE="$2"; shift 2 ;;
      --deploy)        DEPLOY_OVERRIDE="$2"; shift 2 ;;
      --phase)         PHASE="$2"; shift 2 ;;
      --dry-run)       DRY_RUN=true; shift ;;
      --outage-budget) OUTAGE_BUDGET_MIN="$2"; shift 2 ;;
      --skip-prereq-check) SKIP_PREREQ_CHECK=true; shift ;;
      --help|-h)       usage 0 ;;
      *)               die "Unknown argument: $1" ;;
    esac
  done

  # Validate required args
  [[ -n "$OPERATOR" ]] || die "Missing required argument: --operator"
  [[ -n "$PHASE" ]]    || die "Missing required argument: --phase"
  [[ "$PHASE" =~ ^(uninstall|verify)$ ]] || die "Invalid phase: $PHASE (must be uninstall or verify)"
}

# ============================================================================
# Profile loading
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"

# Shared, side-effect-free helpers (probe_ns, discover_seed).
# shellcheck source=lib/ddo-common.sh
source "$SCRIPT_DIR/lib/ddo-common.sh" ||
  { echo "error: cannot source $SCRIPT_DIR/lib/ddo-common.sh" >&2; exit 2; }

load_profile() {
  local profile_file="$PROFILES_DIR/${OPERATOR}-operator-remote.env"
  
  if [[ ! -f "$profile_file" ]]; then
    die "Unknown operator '$OPERATOR': profile not found at $profile_file"
  fi
  
  # shellcheck source=/dev/null
  source "$profile_file"
  PROTECT_MRS="${PROTECT_MRS:-}"
  
  # Apply CLI overrides
  [[ -n "${RELEASE_OVERRIDE:-}" ]] && RELEASE="$RELEASE_OVERRIDE"
  [[ -n "${DDO_CR_OVERRIDE:-}" ]]  && DDO_CR="$DDO_CR_OVERRIDE"
  [[ -n "${DEPLOY_OVERRIDE:-}" ]]  && DEPLOY="$DEPLOY_OVERRIDE"
  
  # Validate required profile fields
  [[ -n "${RELEASE:-}" ]]     || die "Profile missing RELEASE"
  [[ -n "${DDO_CR:-}" ]]      || die "Profile missing DDO_CR"
  [[ -n "${DEPLOY:-}" ]]      || die "Profile missing DEPLOY"
  [[ -n "${CRD_GROUPS:-}" ]]  || die "Profile missing CRD_GROUPS"
  [[ -n "${NAMESPACE_CASCADE_GATE:-}" ]] || die "Profile missing NAMESPACE_CASCADE_GATE"
  [[ -n "${OWNED_BY_LABEL:-}" ]] || die "Profile missing OWNED_BY_LABEL"
  
  info "Loaded profile: $OPERATOR"
  info "  RELEASE=$RELEASE"
  info "  DDO_CR=$DDO_CR"
  info "  DEPLOY=$DEPLOY"
  info "  CRD_GROUPS=$CRD_GROUPS"
  info "  NAMESPACE_CASCADE_GATE=$NAMESPACE_CASCADE_GATE"
}

# ============================================================================
# State directory
# ============================================================================
STATE_DIR=""
init_state_dir() {
  STATE_DIR="${TMPDIR:-/tmp}/ddo-cutover-$OPERATOR-$CLUSTER"
  mkdir -p "$STATE_DIR"
  info "State directory: $STATE_DIR"
}

# ============================================================================
# kubectl/helm wrappers
# ============================================================================
kt() { u8s kubectl --context "$TARGET_CTX" "$@"; }                 # target cluster
ks() { u8s kubectl --context "$SEED_CTX" -n "$NAMESPACE" "$@"; }   # seed cluster, namespaced
ks_global() { u8s kubectl --context "$SEED_CTX" "$@"; }            # seed cluster, global
hs() { u8s helm --kube-context "$SEED_CTX" -n "$NAMESPACE" "$@"; }

# ============================================================================
# obj_state — FAIL-CLOSED state detection
# ============================================================================
# Returns: found | absent | error
# CRITICAL: A connectivity/auth failure can contain "not found" as a substring
# (e.g., "executable login-helper not found"). Only match SERVER-SIDE NotFound:
#   - "Error from server (NotFound)" — genuine per-object NotFound
# A missing-resource-type / API-discovery error ("the server doesn't have a resource")
# must return "error", not "absent" — object-absent ≠ kind-doesn't-exist.
obj_state() {
  local ctxfn="$1"; shift
  local err
  # This read is EXPECTED to fail for genuinely-absent objects; a non-zero exit
  # here is normal and handled below. Under `set -E` the inherited ERR trap
  # would otherwise fire on the failing command inside the substitution and emit
  # a spurious "command failed" line. Clear the trap for this guarded read only,
  # then restore it — fail-closed handling is preserved by the branches below.
  trap - ERR
  local rc=0
  err=$("$ctxfn" "$@" 2>&1 >/dev/null) || rc=$?
  trap 'err_trap "$LINENO" "$BASH_COMMAND"' ERR
  if [[ "$rc" -eq 0 ]]; then
    echo found
    return 0
  fi
  # Check for genuine server-side per-object NotFound ONLY
  # DO NOT match "the server doesn't have a resource type" — that's kind-missing, not object-absent
  if grep -qE 'Error from server \(NotFound\)' <<<"$err"; then
    echo absent
    return 0
  fi
  echo error
  return 0
}

# ============================================================================
# Confirmation gate
# ============================================================================
confirm_token() {
  local token="$1"
  if $DRY_RUN; then
    warn "DRY-RUN: skipping confirmation ($token)"
    return 0
  fi
  printf '\nType EXACTLY the following to proceed:\n  \033[1;31m%s\033[0m\n> ' "$token"
  local ans
  read -r ans
  [[ "$ans" == "$token" ]] || die "Confirmation did not match; nothing changed"
}

# ============================================================================
# Seed discovery — probe_ns / discover_seed provided by lib/ddo-common.sh
# (sourced above). discover_seed assigns SEED_CTX and returns non-zero on
# failure; we translate that into the cutover tool's fail-closed abort.
# ============================================================================

# ============================================================================
# Preflight checks
# ============================================================================

# Gate 1: Target cluster connectivity
preflight_target_connection() {
  step "Preflight: Target cluster connectivity"
  local state
  state=$(obj_state kt get ns default)
  case "$state" in
    found)  ok "Target cluster reachable" ;;
    absent) die "Target cluster reachable but 'default' namespace missing (unexpected)" ;;
    error)  die "Cannot connect to target cluster (context: $TARGET_CTX)" ;;
  esac
}

# Gate 2: CRDs present on target
preflight_crds_on_target() {
  step "Preflight: CRDs present on target"
  local group
  for group in $CRD_GROUPS; do
    local state
    state=$(obj_state kt get crd -l "api-approved.kubernetes.io/group=$group" -o name)
    # Fallback: just check if any CRD from the group exists
    if [[ "$state" != "found" ]]; then
      state=$(obj_state kt get crd -o name)
      if [[ "$state" == "error" ]]; then
        die "Cannot list CRDs on target cluster"
      fi
      # Check if any CRD matches our group
      if ! kt get crd -o name 2>/dev/null | grep -q "$group"; then
        die "CRDs for group $group not found on target cluster"
      fi
    fi
    ok "CRDs for $group present on target"
  done
}

# Gate 3: ManagedResource keepObjects check
preflight_mr_keepobjects() {
  step "Preflight: ManagedResource keepObjects check"
  
  # Check that mr-crd-* ManagedResources have keepObjects:true
  local mr_list
  if ! mr_list=$(ks get managedresource -o json 2>&1); then
    die "Cannot list ManagedResources on seed: $mr_list"
  fi
  
  # Parse MRs belonging to this release (by annotation)
  local crd_mrs
  crd_mrs=$(echo "$mr_list" | jq -r --arg release "$RELEASE" '
    .items[] |
    select(.metadata.annotations["meta.helm.sh/release-name"] == $release) |
    select(.metadata.name | startswith("mr-crd-")) |
    "\(.metadata.name):\(.spec.keepObjects // false)"
  ' 2>/dev/null || true)
  
  local mr_name keep
  while IFS=: read -r mr_name keep; do
    [[ -z "$mr_name" ]] && continue
    if [[ "$keep" != "true" ]]; then
      die "ManagedResource $mr_name does not have keepObjects:true — uninstall would cascade-delete CRDs!"
    fi
    ok "ManagedResource $mr_name has keepObjects:true"
  done <<<"$crd_mrs"
}

# Gate 4: Namespace cascade protection (conditional)
preflight_namespace_cascade() {
  if [[ "$NAMESPACE_CASCADE_GATE" == "off" ]]; then
    info "Namespace cascade gate: OFF (skipping)"
    return
  fi
  
  step "Preflight: Namespace cascade protection"
  
  # Parse: "on <mr-name> <namespace>"
  local gate_mr gate_ns
  read -r _ gate_mr gate_ns <<<"$NAMESPACE_CASCADE_GATE"
  
  if [[ -z "$gate_mr" || -z "$gate_ns" ]]; then
    die "Invalid NAMESPACE_CASCADE_GATE format: $NAMESPACE_CASCADE_GATE"
  fi
  
  info "Checking ManagedResource $gate_mr protects namespace $gate_ns"
  
  protect_namespace_mr "$gate_mr" "$gate_ns"
}

# Patch a namespace ManagedResource to keepObjects:true
protect_namespace_mr() {
  local mr_name="$1"
  # $2 = ns_name (for documentation, unused in implementation)
  
  # Check MR state — fail-closed
  local state
  state=$(obj_state ks get managedresource "$mr_name")
  
  case "$state" in
    found)
      # Check current keepObjects value
      local keep
      keep=$(ks get managedresource "$mr_name" -o jsonpath='{.spec.keepObjects}' 2>/dev/null || echo "")
      if [[ "$keep" == "true" ]]; then
        ok "ManagedResource $mr_name already has keepObjects:true"
      else
        info "Patching ManagedResource $mr_name to keepObjects:true"
        if $DRY_RUN; then
          warn "DRY-RUN: would patch $mr_name"
        else
          if ! ks patch managedresource "$mr_name" --type=merge -p '{"spec":{"keepObjects":true}}'; then
            die "Failed to patch ManagedResource $mr_name"
          fi
          ok "Patched ManagedResource $mr_name"
        fi
      fi
      ;;
    absent)
      # MR not found — not managed by this release, nothing to patch
      warn "ManagedResource $mr_name not found (not managed by this release) — skipping"
      ;;
    error)
      die "Cannot read ManagedResource $mr_name (API error, not NotFound)"
      ;;
  esac
}

# Gate 5: Data-CR ManagedResource protection (conditional)
preflight_protect_mrs() {
  if [[ -z "$PROTECT_MRS" ]]; then
    info "Protect-MRs gate: none (skipping)"
    return
  fi

  step "Preflight: Protect data-CR ManagedResources"

  local mr
  for mr in $PROTECT_MRS; do
    protect_namespace_mr "$mr" ""
  done
}

# Gate 6: Freeze check
preflight_freeze_gate() {
  step "Preflight: Freeze check (deletionTimestamp)"
  
  local fresh_deletes=()
  local stale_deletes=()
  local now_epoch
  now_epoch=$(date +%s)
  
  # Check cluster-scoped kinds
  if [[ -n "${FREEZE_KINDS_CLUSTER:-}" ]]; then
    for kind in $FREEZE_KINDS_CLUSTER; do
      check_freeze_kind_cluster "$kind"
    done
  fi
  
  # Check namespaced kinds (with -A for all namespaces)
  if [[ -n "${FREEZE_KINDS_NS:-}" ]]; then
    for kind in $FREEZE_KINDS_NS; do
      check_freeze_kind_ns "$kind"
    done
  fi
  
  # Server state machine checks (metal-specific)
  if [[ "${FREEZE_SERVER_STATES:-0}" == "1" ]]; then
    check_server_state_machine
  fi
  
  # Report results
  if [[ ${#fresh_deletes[@]} -gt 0 ]]; then
    die "BLOCKED: Fresh deletions in progress (< ${FRESH_DELETE_MIN}m old): ${fresh_deletes[*]}"
  fi
  
  if [[ ${#stale_deletes[@]} -gt 0 ]]; then
    warn "Stale deletions detected (> ${FRESH_DELETE_MIN}m old, pre-existing debt): ${stale_deletes[*]}"
  fi
  
  ok "Freeze check passed"
}

check_freeze_kind_cluster() {
  local kind="$1"
  info "Checking $kind (cluster-scoped) for deletionTimestamp..."
  
  local result
  if ! result=$(kt get "$kind" -o json 2>&1); then
    # Check if it's a "not found" for the CRD itself
    if grep -qE 'the server doesn.t have a resource type|could not find' <<<"$result"; then
      warn "Kind $kind not found on cluster (CRD missing?) — skipping"
      return
    fi
    die "Cannot list $kind: $result"
  fi
  
  parse_deletion_timestamps "$result" "$kind"
}

check_freeze_kind_ns() {
  local kind="$1"
  info "Checking $kind (namespaced, all-namespaces) for deletionTimestamp..."
  
  local result
  if ! result=$(kt get "$kind" -A -o json 2>&1); then
    if grep -qE 'the server doesn.t have a resource type|could not find' <<<"$result"; then
      warn "Kind $kind not found on cluster (CRD missing?) — skipping"
      return
    fi
    die "Cannot list $kind: $result"
  fi
  
  parse_deletion_timestamps "$result" "$kind"
}

parse_deletion_timestamps() {
  local json="$1"
  local kind="$2"
  local now_epoch
  now_epoch=$(date +%s)
  
  # Extract items with deletionTimestamp
  local deleting
  deleting=$(echo "$json" | jq -r '
    .items[] |
    select(.metadata.deletionTimestamp != null) |
    "\(.metadata.name)|\(.metadata.deletionTimestamp)"
  ' 2>/dev/null || true)
  
  while IFS='|' read -r name ts; do
    [[ -z "$name" ]] && continue
    
    # Calculate age — FAIL-CLOSED: unparseable timestamp = treat as fresh = block
    local ts_epoch age_min
    ts_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || date -d "$ts" +%s 2>/dev/null || echo "")
    if [[ -z "$ts_epoch" ]]; then
      fresh_deletes+=("$kind/$name(unparseable-ts)")
      continue
    fi
    age_min=$(( (now_epoch - ts_epoch) / 60 ))
    
    if [[ $age_min -lt $FRESH_DELETE_MIN ]]; then
      fresh_deletes+=("$kind/$name(${age_min}m)")
    else
      stale_deletes+=("$kind/$name(${age_min}m)")
    fi
  done <<<"$deleting"
}

check_server_state_machine() {
  info "Checking Server state machine (metal-specific)..."
  
  local result
  if ! result=$(kt get servers.metal.ironcore.dev -o json 2>&1); then
    if grep -qE 'the server doesn.t have a resource type' <<<"$result"; then
      warn "Server CRD not found — skipping state machine check"
      return
    fi
    die "Cannot list Servers: $result"
  fi
  
  # Check for servers in transitional states
  local transitional
  transitional=$(echo "$result" | jq -r --arg regex "${SERVER_STABLE_STATES_REGEX:-}" '
    .items[] |
    select(.status.state != null) |
    select(.status.state | test($regex) | not) |
    "\(.metadata.name):\(.status.state)"
  ' 2>/dev/null || true)
  
  if [[ -n "$transitional" ]]; then
    die "BLOCKED: Servers in transitional states: $transitional"
  fi
  
  # Check BIOSSettings/BIOSVersion for in-flight operations
  for bios_kind in biossettings.metal.ironcore.dev biosversions.metal.ironcore.dev; do
    local bios_result
    if ! bios_result=$(kt get "$bios_kind" -o json 2>&1); then
      if grep -qE 'the server doesn.t have a resource type' <<<"$bios_result"; then
        continue
      fi
      die "Cannot list $bios_kind: $bios_result"
    fi
    
    # Check for observedGeneration lag
    local lagging
    lagging=$(echo "$bios_result" | jq -r '
      .items[] |
      select(.metadata.deletionTimestamp == null) |
      select(.status.observedGeneration != null and .metadata.generation != null) |
      select(.status.observedGeneration < .metadata.generation) |
      .metadata.name
    ' 2>/dev/null || true)
    
    if [[ -n "$lagging" ]]; then
      die "BLOCKED: $bios_kind with pending changes: $lagging"
    fi
  done
  
  ok "Server state machine check passed"
}

# Gate 6: DDO prerequisites
preflight_ddo_prereqs() {
  if $SKIP_PREREQ_CHECK; then
    warn "Skipping DDO prerequisite checks (--skip-prereq-check)"
    return
  fi
  
  step "Preflight: DDO prerequisites"
  
  # P1: DDO controller Deployment available
  info "P1: Checking DDO controller Deployment..."
  local ddo_deploy_state
  ddo_deploy_state=$(obj_state ks_global get deployment -l app.kubernetes.io/instance=dual-deployment-operator -A -o name)
  case "$ddo_deploy_state" in
    found)  ok "DDO controller Deployment found" ;;
    absent) die "DDO controller Deployment not found (is DDO installed?)" ;;
    error)  die "Cannot check DDO controller Deployment" ;;
  esac
  
  # P2: DualDeploymentOperator CRD established
  info "P2: Checking DualDeploymentOperator CRD..."
  local crd_state
  crd_state=$(obj_state ks_global get crd dualdeploymentoperators.dual-deployment-operator.cc.sap)
  case "$crd_state" in
    found)  ok "DualDeploymentOperator CRD found" ;;
    absent) die "DualDeploymentOperator CRD not found" ;;
    error)  die "Cannot check DualDeploymentOperator CRD" ;;
  esac
  
  # P3: shoot-access Secret (warn only if absent pre-CR-merge)
  info "P3: Checking shoot-access Secret..."
  local secret_state
  secret_state=$(obj_state ks get secret "shoot-access-$DDO_CR")
  case "$secret_state" in
    found)  ok "shoot-access Secret found" ;;
    absent) warn "shoot-access Secret not found (expected before CR PR merge)" ;;
    error)  die "Cannot check shoot-access Secret" ;;
  esac
  
  # P4: Target apiserver authorization
  info "P4: Checking target apiserver authorization..."
  if ! kt auth can-i get crd >/dev/null 2>&1; then
    die "Cannot authorize on target cluster"
  fi
  ok "Target apiserver authorized"
  
  # P5: Operand chart renders cleanly (optional)
  info "P5: Checking operand chart templates..."
  if [[ -n "${OPERAND_CHART_DIR:-}" ]]; then
    local chart_path="$SCRIPT_DIR/../../../$OPERAND_CHART_DIR"
    if [[ -d "$chart_path" ]]; then
      for mode in seed shoot; do
        if ! u8s helm template test "$chart_path" --set "mode=$mode" >/dev/null 2>&1; then
          warn "Chart template failed for mode=$mode (non-blocking)"
        else
          ok "Chart renders for mode=$mode"
        fi
      done
    else
      warn "Chart directory not found: $chart_path (skipping template check)"
    fi
  fi
}

preflight() {
  step "Running preflight checks"
  preflight_target_connection
  preflight_crds_on_target
  preflight_mr_keepobjects
  preflight_namespace_cascade
  preflight_protect_mrs
  preflight_freeze_gate
  preflight_ddo_prereqs
  ok "All preflight checks passed"
}

# ============================================================================
# Baseline snapshot
# ============================================================================
snapshot_baseline() {
  step "Snapshotting baseline state"
  
  # Dump cluster-scoped baseline kinds
  if [[ -n "${BASELINE_SNAPSHOT_KINDS_CLUSTER:-}" ]]; then
    for kind in $BASELINE_SNAPSHOT_KINDS_CLUSTER; do
      info "Snapshotting $kind (cluster-scoped)..."
      kt get "$kind" -o yaml > "$STATE_DIR/baseline-$kind.yaml" 2>/dev/null || true
    done
  fi
  
  # Dump namespaced baseline kinds
  if [[ -n "${BASELINE_SNAPSHOT_KINDS_NS:-}" ]]; then
    for kind in $BASELINE_SNAPSHOT_KINDS_NS; do
      info "Snapshotting $kind (namespaced)..."
      kt get "$kind" -A -o yaml > "$STATE_DIR/baseline-$kind.yaml" 2>/dev/null || true
    done
  fi
  
  # Dump CRD UIDs for UID preservation check
  for group in $CRD_GROUPS; do
    info "Snapshotting CRD UIDs for $group..."
    kt get crd -o json | jq -r --arg group "$group" '
      .items[] |
      select(.spec.group == $group) |
      "\(.metadata.name):\(.metadata.uid)"
    ' > "$STATE_DIR/crd-uids-$group.txt" 2>/dev/null || true
  done
  
  # Report finalizers on live CRs
  info "Checking finalizers on live CRs..."
  for kind in ${BASELINE_SNAPSHOT_KINDS_CLUSTER:-} ${BASELINE_SNAPSHOT_KINDS_NS:-}; do
    local finalizers
    finalizers=$(kt get "$kind" -A -o json 2>/dev/null | jq -r '
      .items[] |
      select(.metadata.finalizers != null and (.metadata.finalizers | length) > 0) |
      "\(.metadata.name): \(.metadata.finalizers | join(", "))"
    ' 2>/dev/null || true)
    if [[ -n "$finalizers" ]]; then
      warn "Finalizers on $kind:"
      echo "$finalizers" | sed 's/^/  /'
    fi
  done
  
  ok "Baseline snapshot complete: $STATE_DIR"
}

# ============================================================================
# Phase: Uninstall
# ============================================================================
phase_uninstall() {
  step "Phase: Uninstall ($OPERATOR)"
  
  # Run preflight
  preflight
  
  # Snapshot baseline
  snapshot_baseline
  
  # Check current release state — FAIL-CLOSED
  step "Checking current Helm release state"
  local release_state
  if hs status "$RELEASE" >/dev/null 2>&1; then
    release_state="found"
    info "Release $RELEASE is currently installed"
  else
    local err
    err=$(hs status "$RELEASE" 2>&1 || true)
    if grep -qE '^Error: release: not found$' <<<"$err"; then
      release_state="absent"
      warn "Release $RELEASE not found — already uninstalled?"
    else
      die "Cannot determine release state (API error): $err"
    fi
  fi
  
  if [[ "$release_state" == "found" ]]; then
    # Capture rollback material
    info "Capturing rollback material..."
    hs get manifest "$RELEASE" > "$STATE_DIR/rollback-manifest.yaml" 2>/dev/null || true
    hs get values "$RELEASE" -o yaml > "$STATE_DIR/rollback-values.yaml" 2>/dev/null || true
    hs get all "$RELEASE" > "$STATE_DIR/rollback-info.txt" 2>/dev/null || true
    
    # DESTRUCTIVE: Uninstall
    confirm_token "UNINSTALL-$RELEASE-$CLUSTER"
    
    if $DRY_RUN; then
      warn "DRY-RUN: would run: helm uninstall $RELEASE"
    else
      info "Uninstalling release $RELEASE..."
      if ! hs uninstall "$RELEASE"; then
        die "Helm uninstall failed"
      fi
      
      # Stamp uninstall epoch for outage budget
      date +%s > "$STATE_DIR/uninstall-epoch"
      ok "Release $RELEASE uninstalled"
    fi
  fi
  
  # Wait for teardown
  if ! $DRY_RUN; then
    wait_for_old_release_gone
  else
    warn "DRY-RUN: skipping teardown barrier"
  fi
  
  # Print handoff instructions
  print_handoff
  
  # Exit 20 = uninstall complete, proceed to merge CR PR
  exit 20
}

# ============================================================================
# Teardown barrier
# ============================================================================
wait_for_old_release_gone() {
  step "Teardown barrier: waiting for old release resources to be removed"
  
  local start_epoch
  start_epoch=$(cat "$STATE_DIR/uninstall-epoch" 2>/dev/null || date +%s)
  local deadline=$((start_epoch + OUTAGE_BUDGET_MIN * 60))
  
  while true; do
    local now
    now=$(date +%s)
    if [[ $now -gt $deadline ]]; then
      print_rollback_plan "teardown-barrier"
      exit 30
    fi
    
    local remaining=$(( (deadline - now) / 60 ))
    info "Checking teardown state (${remaining}m remaining in budget)..."
    
    local all_gone=true
    
    # (a) Check ManagedResources owned by this release (by annotation, not prefix!)
    local mr_list
    if ! mr_list=$(ks get managedresource -o json 2>&1); then
      warn "Cannot list ManagedResources (will retry)"
      all_gone=false
    else
      # Find MRs with this release annotation, excluding mr-crd-* (intentionally retained)
      local owned_mrs
      owned_mrs=$(echo "$mr_list" | jq -r --arg release "$RELEASE" '
        .items[] |
        select(.metadata.annotations["meta.helm.sh/release-name"] == $release) |
        select(.metadata.name | startswith("mr-crd-") | not) |
        .metadata.name
      ' 2>/dev/null || true)
      
      if [[ -n "$owned_mrs" ]]; then
        info "ManagedResources still present: $owned_mrs"
        all_gone=false
      fi
    fi
    
    # (b) Check controller pods
    local pods
    if ! pods=$(ks get pods -l "${CONTROLLER_POD_SELECTOR:-app.kubernetes.io/name=$DEPLOY}" -o name 2>&1); then
      warn "Cannot list pods (will retry)"
      all_gone=false
    elif [[ -n "$pods" ]]; then
      info "Controller pods still present: $pods"
      all_gone=false
    fi
    
    # (c) Namespace survival check (only if namespace-cascade gate is ON)
    if [[ "$NAMESPACE_CASCADE_GATE" != "off" ]]; then
      local gate_ns
      read -r _ _ gate_ns <<<"$NAMESPACE_CASCADE_GATE"
      
      local ns_state
      ns_state=$(obj_state kt get ns "$gate_ns")
      case "$ns_state" in
        found)
          # Check for deletionTimestamp
          local ns_deleting
          ns_deleting=$(kt get ns "$gate_ns" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
          if [[ -n "$ns_deleting" ]]; then
            print_rollback_plan "namespace-terminating"
            die "FATAL: Namespace $gate_ns is terminating — not recoverable by waiting"
          fi
          ;;
        absent)
          print_rollback_plan "namespace-gone"
          die "FATAL: Namespace $gate_ns is gone — not recoverable"
          ;;
        error)
          warn "Cannot check namespace $gate_ns (will retry)"
          all_gone=false
          ;;
      esac
    fi
    
    if $all_gone; then
      ok "Teardown complete — all old release resources removed"
      return
    fi
    
    sleep 10
  done
}

# ============================================================================
# Phase: Verify
# ============================================================================
phase_verify() {
  step "Phase: Verify ($OPERATOR)"
  
  # Check outage budget FIRST
  check_outage_budget
  
  # Run preflight again
  preflight
  
  # Assert DDO CR present and converged
  step "Verifying DDO CR state"
  local cr_state
  cr_state=$(obj_state ks get dualdeploymentoperator "$DDO_CR")
  case "$cr_state" in
    found)  ok "DDO CR $DDO_CR found" ;;
    absent) die "DDO CR $DDO_CR not found — was the CR PR merged?" ;;
    error)  die "Cannot check DDO CR $DDO_CR" ;;
  esac
  
  # Check CR conditions
  local conditions
  conditions=$(ks get dualdeploymentoperator "$DDO_CR" -o jsonpath='{.status.conditions}' 2>/dev/null || echo "[]")
  info "DDO CR conditions: $conditions"
  
  # Assert controller Deployment recreated with DDO ownership
  step "Verifying controller Deployment"
  local deploy_state
  deploy_state=$(obj_state ks get deployment "$DEPLOY")
  case "$deploy_state" in
    found)
      # Check owned-by label
      local owned_by
      owned_by=$(ks get deployment "$DEPLOY" -o jsonpath="{.metadata.labels['$OWNED_BY_LABEL']}" 2>/dev/null || true)
      if [[ -n "$owned_by" ]]; then
        ok "Controller Deployment $DEPLOY found with $OWNED_BY_LABEL=$owned_by"
      else
        warn "Controller Deployment $DEPLOY found but missing $OWNED_BY_LABEL label"
      fi
      ;;
    absent) die "Controller Deployment $DEPLOY not found" ;;
    error)  die "Cannot check controller Deployment $DEPLOY" ;;
  esac
  
  # Assert CRD UIDs unchanged
  step "Verifying CRD UID preservation"
  for group in $CRD_GROUPS; do
    local baseline_file="$STATE_DIR/crd-uids-$group.txt"
    if [[ -f "$baseline_file" ]]; then
      while IFS=: read -r crd_name old_uid; do
        [[ -z "$crd_name" ]] && continue
        local new_uid
        new_uid=$(kt get crd "$crd_name" -o jsonpath='{.metadata.uid}' 2>/dev/null || true)
        if [[ "$new_uid" != "$old_uid" ]]; then
          die "CRD UID changed: $crd_name (was $old_uid, now $new_uid)"
        fi
        ok "CRD UID preserved: $crd_name"
      done < "$baseline_file"
    else
      warn "No baseline CRD UIDs for $group (skipping UID check)"
    fi
  done
  
  # Assert verify sample unaffected
  if [[ -n "${VERIFY_SAMPLE:-}" ]]; then
    step "Verifying do-no-harm sample"
    local sample_state
    # shellcheck disable=SC2086
    sample_state=$(obj_state kt get $VERIFY_SAMPLE)
    case "$sample_state" in
      found)  ok "Verify sample found: $VERIFY_SAMPLE" ;;
      absent) die "Verify sample missing: $VERIFY_SAMPLE" ;;
      error)  die "Cannot check verify sample: $VERIFY_SAMPLE" ;;
    esac
  fi
  
  # Dump controller logs for sanity check
  step "Controller logs (recent)"
  local pod
  pod=$(ks get pods -l "${CONTROLLER_POD_SELECTOR:-app.kubernetes.io/name=$DEPLOY}" -o name 2>/dev/null | head -1 || true)
  if [[ -n "$pod" ]]; then
    ks logs "$pod" --tail=50 2>/dev/null || warn "Could not fetch controller logs"
  else
    warn "No controller pod found for log inspection"
  fi
  
  ok "Verification complete"
}

check_outage_budget() {
  if [[ ! -f "$STATE_DIR/uninstall-epoch" ]]; then
    info "No uninstall epoch found — budget check skipped"
    return
  fi
  
  local start_epoch now elapsed_min
  start_epoch=$(cat "$STATE_DIR/uninstall-epoch")
  now=$(date +%s)
  elapsed_min=$(( (now - start_epoch) / 60 ))
  
  if [[ $elapsed_min -gt $OUTAGE_BUDGET_MIN ]]; then
    print_rollback_plan "budget-blown"
    exit 30
  fi
  
  info "Outage budget: ${elapsed_min}m elapsed of ${OUTAGE_BUDGET_MIN}m"
}

# ============================================================================
# Rollback planner (S0-S3)
# ============================================================================
print_rollback_plan() {
  local trigger="$1"
  
  step "ROLLBACK PLAN (trigger: $trigger)"
  
  # Classify current state — FAIL-CLOSED
  local cr_state deploy_state
  cr_state=$(obj_state ks get dualdeploymentoperator "$DDO_CR")
  deploy_state=$(obj_state ks get deployment "$DEPLOY")
  
  # S0: State unreadable
  if [[ "$cr_state" == "error" || "$deploy_state" == "error" ]]; then
    cat <<EOF

╔═══════════════════════════════════════════════════════════════════════════╗
║  S0: STATE UNREADABLE                                                      ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Cannot determine cluster state due to API errors.                         ║
║                                                                             ║
║  ACTION: DO NOTHING automatically.                                          ║
║  1. Restore connectivity to the seed/target clusters                        ║
║  2. Re-run: $0 --operator $OPERATOR --phase verify ...                      ║
║                                                                             ║
║  DO NOT attempt rollback until state is readable.                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    return
  fi
  
  # S3: New Deployment healthy
  if [[ "$deploy_state" == "found" ]]; then
    local ready
    ready=$(ks get deployment "$DEPLOY" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local owned_by
    owned_by=$(ks get deployment "$DEPLOY" -o jsonpath="{.metadata.labels['$OWNED_BY_LABEL']}" 2>/dev/null || true)
    
    if [[ "${ready:-0}" -gt 0 && -n "$owned_by" ]]; then
      cat <<EOF

╔═══════════════════════════════════════════════════════════════════════════╗
║  S3: NEW DEPLOYMENT HEALTHY                                                ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  The new DDO-managed controller is running and healthy.                     ║
║                                                                             ║
║  ACTION: DO NOT roll back the controller.                                   ║
║  Fix forward:                                                               ║
║  1. Check DDO CR conditions: ks get ddo $DDO_CR -o yaml                     ║
║  2. Check controller logs: ks logs deploy/$DEPLOY                           ║
║  3. Diff CRs vs baseline: $STATE_DIR/baseline-*.yaml                        ║
║  4. If VERIFY_SAMPLE state changed, escalate immediately                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
      return
    fi
  fi
  
  # S1: Clean uninstall state (both CR and Deployment absent)
  if [[ "$cr_state" == "absent" && "$deploy_state" == "absent" ]]; then
    cat <<EOF

╔═══════════════════════════════════════════════════════════════════════════╗
║  S1: CLEAN UNINSTALL STATE                                                 ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Both DDO CR and controller Deployment are absent.                          ║
║                                                                             ║
║  ROLLBACK: Plain helm install of the old chart.                             ║
║                                                                             ║
║  cd $SCRIPT_DIR/../../../${OPERAND_CHART_DIR:-charts/$OPERATOR}
║  helm install $RELEASE . -n $NAMESPACE \\
║    -f $STATE_DIR/rollback-values.yaml
║                                                                             ║
║  Then verify: helm status $RELEASE -n $NAMESPACE                            ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    return
  fi
  
  # S2: Partial state (CR present, or Deployment present, or mismatched)
  cat <<EOF

╔═══════════════════════════════════════════════════════════════════════════╗
║  S2: PARTIAL STATE — CAREFUL CHOREOGRAPHY REQUIRED                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  DDO CR: $cr_state
║  Deployment: $deploy_state
EOF

  if [[ "$NAMESPACE_CASCADE_GATE" != "off" ]]; then
    local gate_ns
    read -r _ _ gate_ns <<<"$NAMESPACE_CASCADE_GATE"
    cat <<EOF
║                                                                             ║
║  DANGEROUS ORDERING (namespace $gate_ns must survive):                      ║
║                                                                             ║
║  1. Scale DDO controller to 0 and WAIT for zero pods:                       ║
║     ks scale deploy/dual-deployment-operator --replicas=0                   ║
║     ks wait --for=delete pod -l app.kubernetes.io/instance=dual-deployment-operator --timeout=60s
║                                                                             ║
║  2. Strip owned-by label from namespace ON TARGET:                          ║
║     kt label ns $gate_ns $OWNED_BY_LABEL-                                   ║
║     Confirm: kt get ns $gate_ns -o jsonpath='{.metadata.labels}'            ║
║                                                                             ║
║  3. Delete the DDO CR and GATE on accepted deletion:                        ║
║     ks delete ddo $DDO_CR                                                   ║
║     Wait for deletionTimestamp to appear (NOT NotFound yet)                 ║
║                                                                             ║
║  4. Restart DDO controller:                                                 ║
║     ks scale deploy/dual-deployment-operator --replicas=1                   ║
║     (finalizer runs, skips unlabelled namespace, cleans up)                 ║
║                                                                             ║
║  5. Verify: CR gone, Deployment gone, namespace $gate_ns EXISTS             ║
║                                                                             ║
║  6. Reinstall old chart:                                                    ║
║     helm install $RELEASE ... -f $STATE_DIR/rollback-values.yaml            ║
EOF
  else
    cat <<EOF
║                                                                             ║
║  ROLLBACK (no namespace-cascade, simpler):                                  ║
║                                                                             ║
║  1. Delete the DDO CR:                                                      ║
║     ks delete ddo $DDO_CR                                                   ║
║     Wait for deletion to complete (NotFound)                                ║
║                                                                             ║
║  2. Reinstall old chart:                                                    ║
║     helm install $RELEASE ... -f $STATE_DIR/rollback-values.yaml            ║
EOF
  fi

  cat <<EOF
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
}

# ============================================================================
# Handoff instructions
# ============================================================================
print_handoff() {
  cat <<EOF

╔═══════════════════════════════════════════════════════════════════════════╗
║  UNINSTALL COMPLETE — HANDOFF                                              ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  The old Helm release has been uninstalled. CRDs and CRs are preserved.     ║
║                                                                             ║
║  NEXT STEPS:                                                                ║
║  1. Merge the DualDeploymentOperator CR PR for $DDO_CR                      ║
║  2. Wait for DDO to reconcile and recreate the controller                   ║
║  3. Run verify phase:                                                       ║
║                                                                             ║
║     $0 --operator $OPERATOR --phase verify \\
║       --cluster $CLUSTER \\
║       --target-context $TARGET_CTX \\
║       --seed-context $SEED_CTX \\
║       --namespace $NAMESPACE
║                                                                             ║
║  OUTAGE BUDGET: ${OUTAGE_BUDGET_MIN} minutes from uninstall epoch           ║
║  State directory: $STATE_DIR                                                ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
}

# ============================================================================
# Main
# ============================================================================
main() {
  parse_args "$@"
  
  # Validate/derive cluster-scoped coordinates for non-help invocations.
  # --cluster names the SHOOT. The shoot's kubectl context is the shoot name,
  # and the seed control-plane namespace is shoot--cp--<shoot>, so both are
  # derived from --cluster unless explicitly overridden.
  if [[ "$PHASE" != "" ]]; then
    [[ -n "$CLUSTER" ]] || die "Missing required argument: --cluster"
    : "${TARGET_CTX:=$CLUSTER}"
    : "${NAMESPACE:=shoot--cp--$CLUSTER}"
  fi
  
  load_profile
  init_state_dir
  discover_seed "$CLUSTER" "$NAMESPACE" || die "Could not auto-discover seed context for namespace $NAMESPACE (pass --seed-context)"
  
  case "$PHASE" in
    uninstall) phase_uninstall ;;
    verify)    phase_verify ;;
  esac
}

main "$@"
