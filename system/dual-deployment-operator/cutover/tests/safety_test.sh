#!/usr/bin/env bash
# Focused failure paths; source the real engine without executing main.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
source "$ROOT/cutover-ddo.sh"
declare -F print_rollback_plan >/dev/null
trap 'rm -rf "$TMP"' EXIT
passed=0; failed=0
test_case() {
  local name=$1; shift
  if ( set -e; "$@" ) >"$TMP/result" 2>&1; then
    echo "PASS: $name"; passed=$((passed+1))
  else
    echo "FAIL: $name"; /usr/bin/tee /dev/null < "$TMP/result"; failed=$((failed+1))
  fi
}
reject() {
  local rc=0
  ( "$@" ) >"$TMP/reject" 2>&1 || rc=$?
  [[ $rc -ne 0 && $rc -ne 127 ]]
}
defaults() {
  OPERATOR=ipam-capi-remote; CLUSTER=m-qa-de-200; TARGET_CTX=shoot; SEED_CTX=seed
  NAMESPACE=cp; RELEASE=legacy; DDO_CR=new; DEPLOY=controller
  OWNED_BY_LABEL=dual-deployment-operator.cc.sap/owned-by
  CRD_GROUPS=ipam.cluster.x-k8s.io; PROTECT_MRS=''; NAMESPACE_CASCADE_GATE=off
  BASELINE_SNAPSHOT_KINDS_CLUSTER=''; BASELINE_SNAPSHOT_KINDS_NS=globalinclusterippools.ipam.cluster.x-k8s.io
  DRY_RUN=false; RESUME=false; PHASE=uninstall; OUTAGE_BUDGET_MIN=20
  STATE_DIR="$TMP/state-$RANDOM"; mkdir -p "$STATE_DIR"
}
bad_capture() { defaults; kt() { echo '{"kind":"List","items":[]}'; return 1; }; reject snapshot_baseline; }
bad_list() { defaults; reject parse_deletion_timestamps '{"items":{}}' pools; }
empty_crds() { defaults; kt() { echo '{"apiVersion":"v1","kind":"List","items":[]}'; }; reject preflight_crds_on_target; }
missing_epoch() { defaults; reject check_outage_budget; }
partial_rollback() {
  defaults; PROTECT_MRS=adopted-data
  obj_state() { echo found; }; ks() { echo '{}'; }
  print_rollback_plan partial >"$TMP/rollback"
  ! grep -Eq 'delete ddo|label ns|helm install|replicas=1' "$TMP/rollback"
}
unknown_rollback() {
  defaults; obj_state() { echo found; }; ks() { return 1; }
  print_rollback_plan unknown >"$TMP/rollback"
  grep -q 'S0' "$TMP/rollback" && ! grep -q 'delete ddo' "$TMP/rollback"
}
missing_baseline() { defaults; reject verify_baseline; }
missing_readiness() { defaults; READINESS_EVIDENCE=''; FREEZE_EVIDENCE=''; reject require_manual_contracts; }
missing_freeze() { defaults; FREEZE_EVIDENCE=''; reject require_freeze; }
epoch_boundary() {
  defaults; OUTAGE_BUDGET_MIN=1
  printf '1000\n' > "$STATE_DIR/uninstall-epoch"
  date() { echo 1060; }
  local rc=0; (check_outage_budget) || rc=$?
  [[ $rc -eq 30 ]]
}
process_bound() {
  defaults
  local rc=0
  evidence run 0.1 python3 -c 'import time; time.sleep(3)' || rc=$?
  [[ $rc -eq 124 ]]
}
lock_conflict() {
  defaults; STATE_DIR_OVERRIDE="$STATE_DIR/root"; mkdir -p "$STATE_DIR_OVERRIDE/.lock"
  reject init_state_dir
  [[ -d "$STATE_DIR_OVERRIDE/.lock" ]]
}
resume_contract() {
  defaults; STATE_DIR_OVERRIDE="$STATE_DIR/root"
  init_state_dir
  mkdir "$STATE_DIR/evidence"; cp "$STATE_DIR/identity.json" "$STATE_DIR/evidence/identity.json"; evidence seal "$STATE_DIR/evidence"
  release_lock; LOCK_DIR=''
  reject init_state_dir
  RESUME=true; init_state_dir; release_lock; LOCK_DIR=''
  RELEASE=another-release; reject init_state_dir
}
dryrun_isolation() {
  defaults; STATE_DIR_OVERRIDE="$STATE_DIR/root"
  init_state_dir; local active=$STATE_DIR; release_lock; LOCK_DIR=''
  DRY_RUN=true; init_state_dir
  [[ "$STATE_DIR" != "$active" && "$STATE_DIR" == */rehearsals/* && -f "$active/identity.json" ]]
}
tampered_baseline() {
  defaults; mkdir "$STATE_DIR/evidence"; echo '{}' > "$STATE_DIR/evidence/fixture.json"
  evidence seal "$STATE_DIR/evidence"
  chmod u+w "$STATE_DIR/evidence/fixture.json"; echo '[]' > "$STATE_DIR/evidence/fixture.json"
  reject verify_baseline
}
known_pool_invariant() {
  defaults
  printf '%s\n' '{"apiVersion":"v1","kind":"List","items":[]}' > "$STATE_DIR/pools.json"
  reject evidence baseline "$STATE_DIR/pools.json" ipam-known-two
}
keep_readback() {
  defaults; ks() { echo '{"kind":"ManagedResource","metadata":{"name":"protected","annotations":{"meta.helm.sh/release-name":"legacy"}},"spec":{"keepObjects":false}}'; }
  reject assert_protected_mr protected
}
wrong_owner() {
  defaults
  printf '%s\n' '{"kind":"Deployment","metadata":{"uid":"u","generation":2,"labels":{"dual-deployment-operator.cc.sap/owned-by":"foreign"}},"spec":{"replicas":2},"status":{"observedGeneration":2,"readyReplicas":2,"availableReplicas":2,"updatedReplicas":2}}' > "$STATE_DIR/deploy.json"
  reject evidence healthy "$STATE_DIR/deploy.json" deployment intended-owner
}
stale_cr() {
  defaults
  printf '%s\n' '{"kind":"DualDeploymentOperator","metadata":{"uid":"u","generation":2},"status":{"conditions":[{"type":"Ready","status":"True","observedGeneration":1}]}}' > "$STATE_DIR/cr.json"
  reject evidence healthy "$STATE_DIR/cr.json" cr
}
failed_uninstall_epoch() {
  defaults
  hs() { case "$1" in status) return 0;; uninstall) [[ -s "$STATE_DIR/uninstall-epoch" ]] || return 99; echo called > "$STATE_DIR/uninstall-called"; return 1;; esac; }
  obj_state() { echo absent; }; require_manual_contracts() { :; }
  capture_evidence() { :; }; preflight() { :; }; verify_baseline() { :; }
  confirm_token() { :; }; recheck_preservation() { :; }
  reject phase_uninstall
  [[ -s "$STATE_DIR/uninstall-epoch" && -f "$STATE_DIR/uninstall-called" ]]
}
repeat_partial_uninstall() {
  defaults; RESUME=true; date +%s > "$STATE_DIR/uninstall-epoch"
  mkdir "$STATE_DIR/evidence"; echo '{}' > "$STATE_DIR/evidence/fixture.json"; evidence seal "$STATE_DIR/evidence"
  hs() { case "$1" in status) return 0;; uninstall) echo unsafe > "$STATE_DIR/unsafe";; esac; }
  obj_state() { echo absent; }; require_manual_contracts() { :; }
  capture_evidence() { echo unsafe > "$STATE_DIR/unsafe"; }
  reject phase_uninstall
  [[ ! -e "$STATE_DIR/unsafe" ]]
}
teardown_parser_failure() {
  defaults; date +%s > "$STATE_DIR/uninstall-epoch"
  ks() { echo '{"apiVersion":"v1","kind":"List","items":{}}'; }
  reject wait_for_old_release_gone
}
missing_archive() {
  defaults; LEGACY_CHART_ARCHIVE=''; hs() { echo '[]'; }
  reject capture_evidence
  [[ ! -d "$STATE_DIR/evidence" ]]
}
baseline_no_overwrite() {
  defaults
  local file="$STATE_DIR/baseline.json"
  echo original > "$file"
  kt() { echo '{"apiVersion":"v1","kind":"List","items":[]}'; }
  reject capture_json "$file" kt
  [[ $(< "$file") == original ]]
}
readonly_before_freeze() {
  defaults; FREEZE_EVIDENCE=''
  preflight_target_connection() { :; }; preflight_crds_on_target() { :; }; preflight_mr_keepobjects() { :; }
  preflight_namespace_cascade() { echo unsafe > "$STATE_DIR/unsafe"; }
  preflight_protect_mrs() { :; }; preflight_freeze_gate() { :; }; preflight_ddo_prereqs() { :; }
  reject preflight
  [[ ! -e "$STATE_DIR/unsafe" ]]
}
fixtures() {
  run_identity > "$STATE_DIR/identity.json"
  python3 "$ROOT/tests/safety_fixtures.py" "$STATE_DIR"
  FREEZE_EVIDENCE="$STATE_DIR/freeze.json"; READINESS_EVIDENCE="$STATE_DIR/readiness.json"
  LEGACY_CHART_ARCHIVE="$STATE_DIR/legacy.tgz"; LEGACY_CHART_DIR=system/ipam-capi-remote
}
readiness_contracts() {
  defaults; fixtures
  require_manual_contracts
  jq '.ddoHTTPFetchVerified = false' "$READINESS_EVIDENCE" > "$STATE_DIR/bad.json"
  READINESS_EVIDENCE="$STATE_DIR/bad.json"
  reject require_manual_contracts
}
dryrun_cannot_certify() {
  defaults; fixtures
  jq '.dryRun = true' "$READINESS_EVIDENCE" > "$STATE_DIR/bad.json"
  READINESS_EVIDENCE="$STATE_DIR/bad.json"
  reject require_manual_contracts
}
missing_render() {
  defaults; fixtures; rm "$STATE_DIR/seedRender.json"
  reject require_manual_contracts
}
missing_restore_contract() {
  defaults; fixtures
  jq 'del(.restoreOnInterruption)' "$FREEZE_EVIDENCE" > "$STATE_DIR/bad.json"
  FREEZE_EVIDENCE="$STATE_DIR/bad.json"
  reject require_freeze
}
valid_capture() {
  defaults; fixtures
  hs() {
    case "$1 $2" in
      'list -a') /usr/bin/tee /dev/null < "$STATE_DIR/releases.json";;
      'get values') echo '{}';;
      'get manifest') /usr/bin/tee /dev/null < "$STATE_DIR/manifest.json";;
      *) return 1;;
    esac
  }
  ks() {
    case "$1" in
      create) /usr/bin/tee /dev/null < "$STATE_DIR/manifest.json";;
      get) /usr/bin/tee /dev/null < "$STATE_DIR/mrs.json";;
      *) return 1;;
    esac
  }
  ks_global() { /usr/bin/tee /dev/null < "$STATE_DIR/controllers.json"; }
  kt() {
    case "$1 $2" in
      'get crd'|'create --dry-run=client') /usr/bin/tee /dev/null < "$STATE_DIR/crds.json";;
      'get globalinclusterippools.ipam.cluster.x-k8s.io') /usr/bin/tee /dev/null < "$STATE_DIR/pools.json";;
      *) return 1;;
    esac
  }
  require_manual_contracts
  capture_evidence
  evidence check "$STATE_DIR/evidence"
  [[ $(jq -r '.metadata.namespace' "$STATE_DIR/evidence/ddo-controller.json") == actual-system ]]
  [[ $(jq -r '.spec.replicas' "$STATE_DIR/evidence/ddo-controller.json") == 3 ]]
  reject capture_evidence
}
missing_embedded_secret() {
  defaults; fixtures
  jq '.items |= map(select(.kind != "Secret"))' "$STATE_DIR/manifest.json" > "$STATE_DIR/bad.json"
  reject evidence embedded-crds "$STATE_DIR/bad.json"
}
missing_expected_crd() {
  defaults; fixtures
  echo '{"kind":"List","apiVersion":"v1","items":[]}' > "$STATE_DIR/empty.json"
  reject evidence crd-coverage "$STATE_DIR/crds.json" "$STATE_DIR/empty.json"
}
reappeared_release() {
  defaults; hs() { echo 'STATUS: deployed'; }
  reject assert_legacy_absent
}
real_object_classifier() {
  defaults
  unreadable() { echo 'exec: login-helper not found' >&2; return 1; }
  missing_kind() { echo "the server doesn't have a resource type" >&2; return 1; }
  missing_object() { echo 'Error from server (NotFound): deployments "x" not found' >&2; return 1; }
  [[ $(obj_state unreadable get deployment x) == error ]]
  [[ $(obj_state missing_kind get deployment x) == error ]]
  [[ $(obj_state missing_object get deployment x) == absent ]]
}
test_case 'legacy release reappearance blocks final verification' reappeared_release
test_case 'real obj_state distinguishes object absence from read/kind errors' real_object_classifier
test_case 'complete valid mocked evidence capture is sealed and cannot repeat' valid_capture
test_case 'IPAM missing HTTP platform proof blocks readiness' readiness_contracts
test_case 'dryrun cannot serve as execution readiness' dryrun_cannot_certify
test_case 'missing actual seed render blocks readiness' missing_render
test_case 'missing interruption restoration contract blocks freeze' missing_restore_contract
test_case 'missing CRD MR referenced Secret blocks inventory extraction' missing_embedded_secret
test_case 'missing exact legacy CRD blocks despite valid empty List' missing_expected_crd
test_case 'capture cannot truncate existing evidence file' baseline_no_overwrite
test_case 'direct preflight cannot patch before mandatory freeze' readonly_before_freeze
test_case 'deadline expires at exact seconds boundary' epoch_boundary
test_case 'whole-process auth latency is bounded' process_bound
test_case 'active lock blocks concurrent invocation' lock_conflict
test_case 'repeat and mismatched resume cannot overwrite evidence' resume_contract
test_case 'dryrun evidence is isolated from active identity' dryrun_isolation
test_case 'altered baseline fails checksum verification' tampered_baseline
test_case 'IPAM known two pools cannot be absent' known_pool_invariant
test_case 'keepObjects reverted readback blocks destruction' keep_readback
test_case 'foreign nonempty owner does not pass health gate' wrong_owner
test_case 'stale Ready=True does not pass CR gate' stale_cr
test_case 'failed uninstall retains epoch recorded before invocation' failed_uninstall_epoch
test_case 'resume of partial uninstall never repeats destructive work' repeat_partial_uninstall
test_case 'teardown parser failure blocks handoff' teardown_parser_failure
test_case 'missing exact legacy archive blocks capture' missing_archive
test_case 'capture failure is fatal' bad_capture
test_case 'invalid List blocks freeze parser' bad_list
test_case 'empty required CRD inventory blocks' empty_crds
test_case 'active verify requires epoch' missing_epoch
test_case 'adopted-data rollback never offers delete/detach/install' partial_rollback
test_case 'secondary read errors classify S0' unknown_rollback
test_case 'missing baseline blocks verification' missing_baseline
test_case 'missing readiness blocks execution' missing_readiness
test_case 'missing freeze blocks execution' missing_freeze
echo "$passed passed; $failed failed"
[[ $failed -eq 0 ]]
