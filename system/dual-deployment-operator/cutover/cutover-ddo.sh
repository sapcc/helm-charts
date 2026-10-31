#!/usr/bin/env bash
# cutover-ddo.sh — Generalized DDO cutover engine (Layer 2)
#
# Usage: cutover-ddo.sh --operator <metal|boot|ipam-capi-remote> --phase <uninstall|verify> \
#          --cluster <shoot> [options]
#
# This script implements the full cutover lifecycle for migrating a Gardener
# extension operator to DualDeploymentOperator management. It is parameterized
# by operator-specific profiles under profiles/<operator>-operator-remote.env (or <operator>.env for exact-name profiles).
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
RESUME=false
STATE_DIR_OVERRIDE=""
FREEZE_EVIDENCE=""
READINESS_EVIDENCE=""
ACCEPTANCE_EVIDENCE=""
LEGACY_CHART_ARCHIVE=""
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
  --resume                Reuse immutable active evidence; required for verify
  --state-dir <dir>       Durable run root (default: ~/.local/state/ddo-cutover/<operator>-<cluster>)
  --freeze-evidence <json> Verified manual reconciler freeze/restoration contract
  --readiness-evidence <json> Reviewed exact source + actual seed/shoot renders
  --legacy-chart-archive <tgz> Exact installed LEGACY chart for recovery
  --acceptance-evidence <json> Functional/do-no-harm evidence for final verify
  --outage-budget <min>   Minutes allowed for cutover (default: 20)
  --skip-prereq-check     Rehearsal-only; never bypass real execution readiness
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
      --resume)        RESUME=true; shift ;;
      --state-dir)     STATE_DIR_OVERRIDE="$2"; shift 2 ;;
      --freeze-evidence) FREEZE_EVIDENCE="$2"; shift 2 ;;
      --readiness-evidence) READINESS_EVIDENCE="$2"; shift 2 ;;
      --acceptance-evidence) ACCEPTANCE_EVIDENCE="$2"; shift 2 ;;
      --legacy-chart-archive) LEGACY_CHART_ARCHIVE="$2"; shift 2 ;;
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
source "$SCRIPT_DIR/lib/cutover-safety.sh" || exit 2

load_profile() {
  local profile_file="$PROFILES_DIR/${OPERATOR}-operator-remote.env"
  [[ -f "$profile_file" ]] || profile_file="$PROFILES_DIR/${OPERATOR}.env"

  if [[ ! -f "$profile_file" ]]; then
    die "Unknown operator '$OPERATOR': profile not found at $profile_file"
  fi
  
  # Reset profile-optional fields so environment values cannot leak between profiles.
  PROTECT_MRS=""
  # shellcheck source=/dev/null
  source "$profile_file"
  
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
  init_safe_state
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
  local group json
  json=$(kt get crd -o json) || die "Cannot list CRDs on target cluster"
  validate_list "$json"
  for group in $CRD_GROUPS; do
    jq -e --arg g "$group" '[.items[] | select(.spec.group == $g and .metadata.deletionTimestamp == null)] | length > 0' <<<"$json" >/dev/null || die "CRDs for group $group missing/terminating"
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
  validate_list "$mr_list"
  check_mr_coverage "$mr_list"
  
  # Parse MRs belonging to this release (by annotation)
  local crd_mrs
  crd_mrs=$(echo "$mr_list" | jq -r --arg release "$RELEASE" '
    .items[] |
    select(.metadata.annotations["meta.helm.sh/release-name"] == $release) |
    select(.metadata.name | startswith("mr-crd-")) |
    "\(.metadata.name):\(.spec.keepObjects // false)"
  ') || die "Cannot parse release CRD MR inventory"
  
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
      local json
      json=$(ks get managedresource "$mr_name" -o json) || die "Cannot read $mr_name"
      jq -e --arg r "$RELEASE" '.kind == "ManagedResource" and .metadata.annotations["meta.helm.sh/release-name"] == $r and .metadata.deletionTimestamp == null' <<<"$json" >/dev/null || die "Foreign/terminating MR $mr_name"
      keep=$(jq -r '.spec.keepObjects // false' <<<"$json") || die "Invalid MR $mr_name"
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
          assert_protected_mr "$mr_name"
        fi
      fi
      ;;
    absent)
      die "Required namespace ManagedResource $mr_name missing"
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
  local -a _protect_mrs
  read -r -a _protect_mrs <<< "$PROTECT_MRS"
  for mr in "${_protect_mrs[@]}"; do
    local state keep
    state=$(obj_state ks get managedresource "$mr")
    case "$state" in
      found)
        if $DRY_RUN; then
          warn "DRY-RUN: would back up $mr"
        fi
        local json
        json=$(ks get managedresource "$mr" -o json) || die "Cannot read $mr"
        jq -e --arg r "$RELEASE" '.kind == "ManagedResource" and .metadata.annotations["meta.helm.sh/release-name"] == $r and .metadata.deletionTimestamp == null' <<<"$json" >/dev/null || die "Foreign/terminating MR $mr"
        keep=$(jq -r '.spec.keepObjects // false' <<<"$json") || die "Invalid MR $mr"
        if [[ "$keep" == "true" ]]; then
          ok "ManagedResource $mr already has keepObjects:true"
        elif $DRY_RUN; then
          warn "DRY-RUN: would patch $mr"
        else
          info "Patching ManagedResource $mr to keepObjects:true"
          if ! ks patch managedresource "$mr" --type=merge -p '{"spec":{"keepObjects":true}}'; then
            die "Failed to patch ManagedResource $mr"
          fi
          assert_protected_mr "$mr"
          ok "Patched ManagedResource $mr"
        fi
        ;;
      absent) die "PROTECT_MRS entry $mr not found on seed — refusing to uninstall, data-CR would be cascade-deleted" ;;
      error)  die "Cannot read PROTECT_MRS entry $mr on seed — refusing to uninstall, data-CR would be cascade-deleted" ;;
    esac
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
    die "Cannot list $kind: $result"
  fi
  
  parse_deletion_timestamps "$result" "$kind"
}

check_freeze_kind_ns() {
  local kind="$1"
  info "Checking $kind (namespaced, all-namespaces) for deletionTimestamp..."
  
  local result
  if ! result=$(kt get "$kind" -A -o json 2>&1); then
    die "Cannot list $kind: $result"
  fi
  
  parse_deletion_timestamps "$result" "$kind"
}

parse_deletion_timestamps() {
  local json="$1"
  local kind="$2"
  validate_list "$json"
  local now_epoch
  now_epoch=$(date +%s)
  
  # Extract items with deletionTimestamp
  local deleting
  deleting=$(echo "$json" | jq -r '
    .items[] |
    select(.metadata.deletionTimestamp != null) |
    "\(.metadata.name)|\(.metadata.deletionTimestamp)"
  ') || die "Cannot parse deletion timestamps for $kind"
  
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
    die "Cannot list Servers: $result"
  fi
  validate_list "$result"
  # Check for servers in transitional states
  local transitional
  transitional=$(echo "$result" | jq -r --arg regex "${SERVER_STABLE_STATES_REGEX:-}" '
    .items[] |
    select(.status.state != null) |
    select(.status.state | test($regex) | not) |
    "\(.metadata.name):\(.status.state)"
  ') || die "Cannot parse Server states"
  
  if [[ -n "$transitional" ]]; then
    die "BLOCKED: Servers in transitional states: $transitional"
  fi
  
  # Check BIOSSettings/BIOSVersion for in-flight operations
  for bios_kind in biossettings.metal.ironcore.dev biosversions.metal.ironcore.dev; do
    local bios_result
    if ! bios_result=$(kt get "$bios_kind" -o json 2>&1); then
      die "Cannot list $bios_kind: $bios_result"
    fi
    validate_list "$bios_result"
    
    # Check for observedGeneration lag
    local lagging
    lagging=$(echo "$bios_result" | jq -r '
      .items[] |
      select(.metadata.deletionTimestamp == null) |
      select(.status.observedGeneration != null and .metadata.generation != null) |
      select(.status.observedGeneration < .metadata.generation) |
      .metadata.name
    ') || die "Cannot parse $bios_kind"
    
    if [[ -n "$lagging" ]]; then
      die "BLOCKED: $bios_kind with pending changes: $lagging"
    fi
  done
  
  ok "Server state machine check passed"
}

# Gate 6: DDO prerequisites
preflight_ddo_prereqs() {
  if $SKIP_PREREQ_CHECK; then
    $DRY_RUN || die "--skip-prereq-check is rehearsal-only"
    warn "REHEARSAL ONLY: skipping DDO prerequisite checks; NOT execution readiness"
    return
  fi
  
  step "Preflight: DDO prerequisites"
  
  # P1: DDO controller Deployment available
  info "P1: Checking DDO controller Deployment..."
  local deployments
  deployments=$(ks_global get deployment -l app.kubernetes.io/instance=dual-deployment-operator -A -o json) || die "Cannot check DDO Deployment"
  validate_list "$deployments"
  jq -e '.items | length == 1' <<<"$deployments" >/dev/null || die "Expected exactly one DDO controller"
  check_ddo_coordinates "$deployments"
  
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
  
  # Actual seed/shoot renders and installed platform support are mandatory
  # operator evidence, not inferred from a local default-values Helm render.
  if $DRY_RUN; then
    warn "REHEARSAL ONLY: no source/platform readiness certification"
  else
    require_manual_contracts
  fi
}

preflight() {
  step "Running preflight checks"
  if ! $DRY_RUN; then require_manual_contracts; fi
  preflight_target_connection
  preflight_crds_on_target
  if [[ "$PHASE" == uninstall ]]; then
    preflight_mr_keepobjects
    preflight_namespace_cascade
    preflight_protect_mrs
  fi
  preflight_freeze_gate
  preflight_ddo_prereqs
  ok "All preflight checks passed"
}

# ============================================================================
# Baseline snapshot
# ============================================================================
snapshot_baseline() {
  capture_baselines "$STATE_DIR"
}

# ============================================================================
# Phase: Uninstall
# ============================================================================
phase_uninstall() {
  step "Phase: Uninstall ($OPERATOR)"
  # Check release and DDO BEFORE any capture; resume never refreshes evidence.
  step "Checking current Helm release state"
  local release_state
  local status_output
  if status_output=$(hs status "$RELEASE" 2>&1); then
    release_state="found"
    info "Release $RELEASE is currently installed"
  else
    local err
    err="$status_output"
    if grep -qE '^Error: release: not found$' <<<"$err"; then
      release_state="absent"
      warn "Release $RELEASE not found — already uninstalled?"
    else
      die "Cannot determine release state (API error): $err"
    fi
  fi
  local cr_state
  cr_state=$(obj_state ks get dualdeploymentoperator "$DDO_CR")
  [[ "$cr_state" == absent ]] || die "DDO state is $cr_state; S0/S2 manual recovery required, no uninstall or recapture"
  if ! $DRY_RUN; then require_manual_contracts; fi
  if $RESUME; then
    evidence check "$STATE_DIR/evidence" || die "Resume evidence invalid"
    if [[ -f "$STATE_DIR/uninstall-epoch" ]]; then
      check_outage_budget
      [[ "$release_state" == absent ]] || die "Interrupted/partial uninstall: S0 manual recovery; never automatically repeat uninstall"
    else
      [[ "$release_state" == found ]] || die "Release disappeared without epoch; S0 manual recovery"
    fi
  else
    [[ "$release_state" == found ]] || die "Initial release absent; refusing post-cutover baseline capture"
    capture_evidence
  fi
  if [[ "$release_state" == found ]]; then
    preflight
    verify_baseline
    confirm_token "UNINSTALL-$RELEASE-$CLUSTER"
    if $DRY_RUN; then
      warn "REHEARSAL ONLY: would uninstall $RELEASE; no readiness or handoff certified"
      return 0
    else
      require_manual_contracts
      # Durable epoch BEFORE any destructive operation, including failed uninstall.
      local epoch_input
      epoch_input=$(mktemp "$STATE_DIR/.epoch.XXXXXX")
      date +%s > "$epoch_input"
      evidence publish "$STATE_DIR/uninstall-epoch" "$epoch_input" || die "Cannot persist outage epoch"
      rm "$epoch_input"
      recheck_preservation
      check_outage_budget
      info "Uninstalling release $RELEASE..."
      if ! hs uninstall "$RELEASE"; then
        die "Helm uninstall failed"
      fi
      
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
  
  while true; do
    check_outage_budget
    local remaining
    remaining=$(remaining_seconds) || die "Cannot read outage deadline"
    info "Checking teardown state (${remaining}s remaining in budget)..."
    
    local all_gone=true
    
    # (a) Check ManagedResources owned by this release (by annotation, not prefix!)
    local mr_list
    if ! mr_list=$(ks get managedresource -o json 2>&1); then
      warn "Cannot list ManagedResources (will retry)"
      all_gone=false
    else
      validate_list "$mr_list"
      # Find MRs with this release annotation, excluding mr-crd-* (intentionally retained)
      local owned_mrs
      owned_mrs=$(echo "$mr_list" | jq -r --arg release "$RELEASE" '
        .items[] |
        select(.metadata.annotations["meta.helm.sh/release-name"] == $release) |
        select(.metadata.name | startswith("mr-crd-") | not) |
        .metadata.name
      ') || die "Invalid teardown MR inventory"
      
      if [[ -n "$owned_mrs" ]]; then
        info "ManagedResources still present: $owned_mrs"
        all_gone=false
      fi
    fi
    
    # (b) Check controller pods
    local pods
    if ! pods=$(ks get pods -l "${CONTROLLER_POD_SELECTOR:-app.kubernetes.io/name=$DEPLOY}" -o json 2>&1); then
      warn "Cannot list pods (will retry)"
      all_gone=false
    else
      validate_list "$pods"
      if [[ $(jq '.items | length' <<<"$pods") -gt 0 ]]; then all_gone=false; fi
    fi
    
    # (c) Namespace survival check (only if namespace-cascade gate is ON)
    if [[ "$NAMESPACE_CASCADE_GATE" != "off" ]]; then
      local gate_ns
      read -r _ _ gate_ns <<<"$NAMESPACE_CASCADE_GATE"
      
      assert_namespace "$gate_ns"
    fi
    
    if $all_gone; then
      check_outage_budget
      assert_legacy_absent
      verify_baseline
      check_outage_budget
      ok "Teardown complete — all old release resources removed"
      return
    fi
    
    remaining=$(remaining_seconds) || die "Cannot read deadline"
    [[ $remaining -gt 0 ]] || check_outage_budget
    [[ $remaining -gt 10 ]] || { sleep "$remaining"; check_outage_budget; }
    sleep 10
  done
}

# ============================================================================
# Phase: Verify
# ============================================================================
phase_verify() {
  step "Phase: Verify ($OPERATOR)"
  $DRY_RUN && die "Dry-run cannot certify active cutover verification"
  
  # Check outage budget FIRST
  check_outage_budget
  
  # Run preflight again
  preflight
  assert_legacy_absent
  
  verify_controller_health
  verify_baseline
  
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
  
  check_outage_budget
  [[ -n "$ACCEPTANCE_EVIDENCE" ]] || die "Automated preservation/health gates passed, but --acceptance-evidence is required for functional/do-no-harm acceptance"
  evidence contract "$ACCEPTANCE_EVIDENCE" "$STATE_DIR/identity.json" acceptance || die "Functional acceptance incomplete"
  evidence publish "$STATE_DIR/acceptance.json" "$ACCEPTANCE_EVIDENCE" || die "Acceptance already recorded or cannot be persisted (no overwrite)"
  check_outage_budget
  ok "Automated preservation/health gates and recorded manual functional acceptance passed"
  warn "Keep legacy desired state disabled; execute only the recorded success restoration contract"
}

check_outage_budget() {
  local remaining
  remaining=$(remaining_seconds) || die "Active cutover requires valid outage epoch"
  if [[ $remaining -le 0 ]]; then
    warn "S0: deadline reached; state unknown. Manual recovery required; DO NOT delete/detach DDO or restore the legacy reconciler blindly."
    exit 30
  fi
  info "Outage budget: ${remaining}s remaining"
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
    local json cr_json owner health_dir
    if ! json=$(ks get deployment "$DEPLOY" -o json) || ! cr_json=$(ks get dualdeploymentoperator "$DDO_CR" -o json); then
      warn "S0: secondary state read failed. Manual recovery blocked until state is readable; no detach/delete."
      return
    fi
    if ! jq -e '.kind == "Deployment" and (.metadata | type == "object")' <<<"$json" >/dev/null || ! jq -e '.kind == "DualDeploymentOperator" and (.metadata | type == "object")' <<<"$cr_json" >/dev/null; then
      warn "S0: malformed secondary state. No automated recovery."
      return
    fi
    health_dir=$(mktemp -d "$STATE_DIR/.rollback-health.XXXXXX")
    printf '%s\n' "$json" > "$health_dir/deploy.json"
    printf '%s\n' "$cr_json" > "$health_dir/cr.json"
    if owner=$(jq -er '.expectedOwnerValue' "$STATE_DIR/evidence/readiness.json" 2>/dev/null) && evidence healthy "$health_dir/deploy.json" deployment "$owner" && evidence healthy "$health_dir/cr.json" cr; then
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
║  3. Diff CRs vs baseline: $STATE_DIR/evidence/baseline-*.json               ║
║  4. If VERIFY_SAMPLE state changed, escalate immediately                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
      return
    fi
  fi
  
  # S1: Clean uninstall state (both CR and Deployment absent)
  if [[ "$cr_state" == "absent" && "$deploy_state" == "absent" ]]; then
    if ! evidence check "$STATE_DIR/evidence"; then
      warn "S0: exact legacy recovery artifacts unavailable/altered. Recovery blocked; no guessed chart installation."
      return
    fi
    warn "S1 candidate only: manual inventory/UID/deletionTimestamp review on BOTH clusters and disable DDO desired state before recovery. CR absence alone does not prove teardown or preservation."
    warn "After specialist approval and the recorded rollback restoration contract ONLY, the exact captured legacy recovery command is:"
    printf '  u8s helm --kube-context %q -n %q install %q %q -f %q\n' "$SEED_CTX" "$NAMESPACE" "$RELEASE" "$STATE_DIR/evidence/legacy-chart.tgz" "$STATE_DIR/evidence/rollback-values.json"
    printf '  u8s helm --kube-context %q -n %q status %q\n' "$SEED_CTX" "$NAMESPACE" "$RELEASE"
    return
  fi
  
  cat <<EOF
S2: PARTIAL STATE — AUTOMATED RECOVERY BLOCKED (CR=$cr_state, Deployment=$deploy_state).
Do NOT delete the DDO CR or detach ownership. Finalizers are not backups:
adopted data CRs and protected namespaces can be irreversibly deleted.
Keep the legacy reconciler frozen. Escalate for a reviewed recovery plan that
examines actual seed/shoot inventories, retention, exact baseline UIDs and
deletionTimestamp. No automatic stop/restore/detach sequence is provided.
Actual DDO coordinates, UID, selector and original replicas are recorded at:
  $STATE_DIR/evidence/ddo-controller.json
Use the recorded freeze restoration contract for interruption/rollback; never
restore the legacy desired state alongside active DDO ownership.
EOF
}

# ============================================================================
# Handoff instructions
# ============================================================================
print_handoff() {
  if $DRY_RUN; then
    warn "REHEARSAL ONLY: no uninstall, no handoff, no execution-readiness certification"
    return
  fi
  check_outage_budget
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
║       --namespace $NAMESPACE --release $RELEASE --ddo-cr $DDO_CR --deploy $DEPLOY \\
║       --outage-budget $OUTAGE_BUDGET_MIN --resume --state-dir ${STATE_DIR%/active} \\
║       --freeze-evidence <current-freeze.json> --readiness-evidence <readiness.json> \\
║       --acceptance-evidence <functional-acceptance.json>
║                                                                             ║
║  OUTAGE BUDGET: ${OUTAGE_BUDGET_MIN} minutes from uninstall epoch           ║
║  State directory: $STATE_DIR                                                ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
  warn "Keep an external outage clock running. Keep legacy desired state disabled; restore only via the recorded success/rollback/interruption contract."
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
  if $RESUME && [[ -z "$SEED_CTX" ]]; then
    die "--resume requires the original explicit --seed-context (no discovery outside the active deadline)"
  fi
  discover_seed "$CLUSTER" "$NAMESPACE" || die "Could not auto-discover seed context for namespace $NAMESPACE (pass --seed-context)"
  init_state_dir
  
  case "$PHASE" in
    uninstall) phase_uninstall ;;
    verify)    phase_verify ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
