#!/usr/bin/env bash
# Engine-only safety helpers. No cluster reads or filesystem changes at source time.
evidence() { python3 "$SCRIPT_DIR/lib/cutover-evidence.py" "$@"; }

validate_list() {
  jq -e 'type == "object" and (.apiVersion | type == "string") and
    (.kind | type == "string" and endswith("List")) and (.items | type == "array") and
    all(.items[]; (.metadata.name | type == "string" and length > 0))' >/dev/null <<<"$1" || die "Invalid Kubernetes JSON List"
}

remaining_seconds() {
  local epoch now
  [[ -f "$STATE_DIR/uninstall-epoch" ]] || die "Missing durable outage epoch; manual recovery required"
  IFS= read -r epoch < "$STATE_DIR/uninstall-epoch"
  [[ "$epoch" =~ ^[0-9]+$ ]] || die "Invalid outage epoch"
  now=$(date +%s)
  [[ $epoch -le $now ]] || die "Outage epoch is in the future"
  echo "$((epoch + OUTAGE_BUDGET_MIN * 60 - now))"
}

bounded_call() {
  local seconds=60 remaining rc=0
  if [[ -n "${STATE_DIR:-}" && -f "$STATE_DIR/uninstall-epoch" ]]; then
    remaining=$(remaining_seconds) || return 2
    if [[ $remaining -le 0 ]]; then
      echo 'Outage deadline exhausted; S0/manual recovery only. Keep the legacy reconciler frozen.' >&2
      return 30
    fi
    [[ $remaining -ge $seconds ]] || seconds=$remaining
  fi
  evidence run "$seconds" "$@" || rc=$?
  [[ $rc -ne 124 ]] || echo 'Call timed out including authentication; state is unknown. Do not detach/delete DDO.' >&2
  return "$rc"
}

# Also bounds discovery's calls, without changing the shared scanner helper.
u8s() { bounded_call u8s "$@"; }

run_identity() {
  evidence identity "$OPERATOR" "$CLUSTER" "$TARGET_CTX" "$SEED_CTX" "$NAMESPACE" \
    "$RELEASE" "$DDO_CR" "$DEPLOY" "$((OUTAGE_BUDGET_MIN * 60))" \
    "$CRD_GROUPS|$NAMESPACE_CASCADE_GATE|${PROTECT_MRS:-}|${BASELINE_SNAPSHOT_KINDS_CLUSTER:-}|${BASELINE_SNAPSHOT_KINDS_NS:-}|$OWNED_BY_LABEL|${FREEZE_KINDS_CLUSTER:-}|${FREEZE_KINDS_NS:-}|${FREEZE_SERVER_STATES:-0}|${CONTROLLER_POD_SELECTOR:-}|${VERIFY_SAMPLE:-}"
}

release_lock() {
  if [[ -n "${LOCK_DIR:-}" ]]; then
    rm -f "$LOCK_DIR/owner"
    rmdir "$LOCK_DIR" || true
  fi
}

init_safe_state() {
  umask 077
  [[ "$OUTAGE_BUDGET_MIN" =~ ^[1-9][0-9]*$ && ${#OUTAGE_BUDGET_MIN} -le 5 ]] || die "Budget must be positive integer minutes (maximum 99999)"
  local base="${STATE_DIR_OVERRIDE:-${XDG_STATE_HOME:-$HOME/.local/state}/ddo-cutover/$OPERATOR-$CLUSTER}"
  if $DRY_RUN; then
    $RESUME && die "--resume cannot use --dry-run evidence"
    mkdir -p "$base/rehearsals"
    STATE_DIR=$(mktemp -d "$base/rehearsals/run.XXXXXX")
  else
    STATE_DIR="$base/active"
    mkdir -p "$base"
  fi
  LOCK_DIR="$base/.lock"
  mkdir "$LOCK_DIR" 2>/dev/null || die "Run locked: $LOCK_DIR (stale lock requires manual process inspection; never auto-break)"
  printf 'pid=%s host=%s\n' "$$" "$(hostname)" > "$LOCK_DIR/owner"
  trap release_lock EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  local identity
  identity=$(run_identity) || die "Cannot construct run identity"
  if [[ -f "$STATE_DIR/identity.json" ]]; then
    $RESUME || die "Active run exists; use --resume with identical coordinates (no overwrite)"
    [[ "$(jq -Sc . "$STATE_DIR/identity.json")" == "$(jq -Sc . <<<"$identity")" ]] || die "Resume identity mismatch"
    evidence check "$STATE_DIR/evidence" || die "Incomplete/altered active evidence; S0 manual recovery (no recapture)"
    cmp -s "$STATE_DIR/identity.json" "$STATE_DIR/evidence/identity.json" || die "Active identity differs from sealed run identity"
  else
    $RESUME && die "No active run to resume"
    [[ "$PHASE" != verify ]] || die "Verify requires --resume of an active cutover"
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$identity" > "$STATE_DIR/.identity-input"
    evidence publish "$STATE_DIR/identity.json" "$STATE_DIR/.identity-input" || die "Cannot publish run identity"
    rm "$STATE_DIR/.identity-input"
  fi
  info "State directory: $STATE_DIR"
}

require_freeze() {
  local file="${FREEZE_EVIDENCE:-}"
  [[ -n "$file" && -f "$file" ]] || die "--freeze-evidence required: actual reconciler, original state, proof, and success/rollback/interruption restoration contract"
  evidence contract "$file" "$STATE_DIR/identity.json" freeze || die "Legacy reconciler freeze is not verified"
  if [[ -f "$STATE_DIR/evidence/freeze.json" ]]; then
    local fields='del(.verifiedBy, .verifiedAtEpoch, .freezeProof)'
    [[ $(jq -Sc "$fields" "$file") == "$(jq -Sc "$fields" "$STATE_DIR/evidence/freeze.json")" ]] || die "Freeze original-state/restoration contract changed since capture"
  fi
}

require_manual_contracts() {
  require_freeze
  [[ -n "${READINESS_EVIDENCE:-}" && -f "$READINESS_EVIDENCE" ]] || die "--readiness-evidence required; installed version strings alone do not prove delivery readiness"
  evidence contract "$READINESS_EVIDENCE" "$STATE_DIR/identity.json" readiness || die "Source/release readiness not established"
  if [[ -f "$STATE_DIR/evidence/readiness.json" ]]; then
    local fields='del(.verifiedBy, .verifiedAtEpoch)'
    [[ $(jq -Sc "$fields" "$READINESS_EVIDENCE") == "$(jq -Sc "$fields" "$STATE_DIR/evidence/readiness.json")" ]] || die "Readiness/source changed since immutable capture"
  fi
}

capture_json() {
  local path=$1; shift
  [[ ! -e "$path" ]] || die "Refusing to overwrite existing capture: $path"
  "$@" > "$path" || die "Required capture failed: $path"
  evidence list "$path" || die "Invalid inventory capture: $path"
}

capture_baselines() {
  local dir=$1 kind group
  for kind in ${BASELINE_SNAPSHOT_KINDS_CLUSTER:-} ${BASELINE_SNAPSHOT_KINDS_NS:-}; do
    local args=()
    case " ${BASELINE_SNAPSHOT_KINDS_NS:-} " in *" $kind "*) args=(-A);; esac
    capture_json "$dir/baseline-$kind.json" kt get "$kind" "${args[@]}" -o json
    local invariant=ordinary
    if [[ "$OPERATOR" == ipam-capi-remote && "$CLUSTER" == m-qa-de-200 && "$kind" == globalinclusterippools.ipam.cluster.x-k8s.io ]]; then
      invariant=ipam-known-two
    fi
    evidence baseline "$dir/baseline-$kind.json" "$invariant" || die "Invalid baseline for $kind"
    if [[ -n "${PROTECT_MRS:-}" ]]; then
      jq -e '.items | length > 0' "$dir/baseline-$kind.json" >/dev/null || die "Empty required adopted-data inventory: $kind"
    fi
  done
  capture_json "$dir/all-crds.json" kt get crd -o json
  local expected='[]'
  if [[ -f "$dir/legacy-crds.json" ]]; then
    expected=$(jq '[.items[].metadata.name]' "$dir/legacy-crds.json") || die "Invalid expected CRD inventory"
  fi
  jq --arg groups "$CRD_GROUPS" --argjson expected "$expected" '.items |= map(select(. as $crd | ($groups | split(" ") | index($crd.spec.group)) != null or ($expected | index($crd.metadata.name)) != null))' "$dir/all-crds.json" > "$dir/baseline-crds.json" || die "Cannot select CRD baseline"
  evidence baseline "$dir/baseline-crds.json" || die "CRD baseline capture invalid"
  for group in $CRD_GROUPS; do
    jq -e --arg g "$group" '[.items[] | select(.spec.group == $g)] | length > 0' "$dir/baseline-crds.json" >/dev/null || die "Empty required CRD group $group"
  done
}

capture_evidence() {
  [[ ! -e "$STATE_DIR/evidence" ]] || die "Refusing to overwrite captured evidence"
  local dir
  dir=$(mktemp -d "$STATE_DIR/.capture.XXXXXX")
  cp "$STATE_DIR/identity.json" "$dir/identity.json" || die "Cannot bind evidence to run identity"
  hs list -a -o json > "$dir/releases.json" || die "Cannot capture installed release metadata"
  [[ -n "${LEGACY_CHART_ARCHIVE:-}" && -f "$LEGACY_CHART_ARCHIVE" ]] || die "--legacy-chart-archive exact installed legacy .tgz is required"
  cp "$LEGACY_CHART_ARCHIVE" "$dir/legacy-chart.tgz" || die "Cannot copy legacy archive"
  evidence chart "$dir/legacy-chart.tgz" "$dir/releases.json" "$RELEASE" "${LEGACY_CHART_DIR##*/}" || die "Exact installed legacy chart unavailable"
  if ! $DRY_RUN; then
    local archive_hash
    archive_hash=$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$dir/legacy-chart.tgz") || die "Cannot hash recovery archive"
    [[ "$archive_hash" == "$(jq -er '.legacyArchiveSha256' "$READINESS_EVIDENCE")" ]] || die "Legacy archive differs from reviewed recovery artifact"
  fi
  hs get values "$RELEASE" -o json > "$dir/rollback-values.json" || die "Rollback values capture failed"
  jq -e 'type == "object" or . == null' "$dir/rollback-values.json" >/dev/null || die "Invalid rollback values"
  # Helm returns null when there are no user-supplied values; {} is equivalent.
  if [[ $(jq -r type "$dir/rollback-values.json") == null ]]; then printf '{}\n' > "$dir/rollback-values.json"; fi
  hs get manifest "$RELEASE" > "$dir/rollback-manifest.yaml" || die "Rollback manifest capture failed"
  [[ -s "$dir/rollback-manifest.yaml" ]] || die "Empty legacy manifest"
  # Kubernetes handles YAML decoding; this is CLIENT dry-run, never server create.
  ks create --dry-run=client --validate=false -f "$dir/rollback-manifest.yaml" -o json > "$dir/manifest-stream.json" || die "Cannot decode legacy manifest"
  evidence normalize "$dir/manifest-stream.json" > "$dir/legacy-manifest.json" || die "Invalid legacy manifest"
  evidence embedded-crds "$dir/legacy-manifest.json" > "$dir/legacy-crds.yaml" || die "Cannot extract CRD inventory from installed legacy manifest"
  kt create --dry-run=client --validate=false -f "$dir/legacy-crds.yaml" -o json > "$dir/crd-stream.json" || die "Cannot decode legacy CRDs"
  evidence normalize "$dir/crd-stream.json" > "$dir/legacy-crds.json" || die "Invalid legacy CRD inventory"
  capture_baselines "$dir"
  evidence crd-coverage "$dir/legacy-crds.json" "$dir/baseline-crds.json" || die "Incomplete live CRD inventory"
  capture_json "$dir/live-managedresources.json" ks get managedresource -o json
  if [[ "$NAMESPACE_CASCADE_GATE" != off ]]; then
    local gate_ns namespace_json
    read -r _ _ gate_ns <<< "$NAMESPACE_CASCADE_GATE"
    namespace_json=$(kt get namespace "$gate_ns" -o json) || die "Cannot snapshot protected namespace"
    jq -e '.kind == "Namespace" and (.metadata.uid | type == "string" and length > 0) and .metadata.deletionTimestamp == null' <<<"$namespace_json" >/dev/null || die "Protected namespace missing/terminating/malformed"
    printf '%s\n' "$namespace_json" > "$dir/protected-namespace.json"
  fi
  capture_json "$dir/ddo-deployments.json" ks_global get deployment -A -l app.kubernetes.io/instance=dual-deployment-operator -o json
  jq -e '.items | length == 1' "$dir/ddo-deployments.json" >/dev/null || die "Expected exactly one installed DDO Deployment"
  jq '.items[0]' "$dir/ddo-deployments.json" > "$dir/ddo-controller.json"
  evidence healthy "$dir/ddo-controller.json" deployment || die "Installed DDO controller is not healthy"
  jq -e '.metadata.namespace | type == "string" and length > 0' "$dir/ddo-controller.json" >/dev/null || die "Missing actual DDO coordinates"
  if ! $DRY_RUN; then
    cp "$READINESS_EVIDENCE" "$dir/readiness.json" || die "Cannot copy readiness"
    cp "$FREEZE_EVIDENCE" "$dir/freeze.json" || die "Cannot copy freeze"
    local key file
    for key in seedRender shootRender ddoCRManifest; do
      file=$(jq -er --arg key "$key" '.[$key].file' "$READINESS_EVIDENCE") || die "Missing readiness artifact"
      [[ "$file" != /* ]] || die "Readiness artifact paths must be relative"
      cp "$(dirname "$READINESS_EVIDENCE")/$file" "$dir/$key.json" || die "Cannot copy $key"
    done
    evidence contract "$dir/readiness.json" "$dir/identity.json" readiness stored || die "Copied readiness/artifacts changed during capture"
    evidence contract "$dir/freeze.json" "$dir/identity.json" freeze || die "Copied freeze evidence invalid"
    [[ "$archive_hash" == "$(jq -er '.legacyArchiveSha256' "$dir/readiness.json")" ]] || die "Recovery archive attestation changed during capture"
    # Bind the reviewed exact source to the intended DDO coordinates.
    jq -e --arg n "$DDO_CR" --arg ns "$NAMESPACE" '.items | length == 1 and .[0].kind == "DualDeploymentOperator" and .[0].metadata.name == $n and .[0].metadata.namespace == $ns and (.[0].spec.source | type == "object")' "$dir/ddoCRManifest.json" >/dev/null || die "Reviewed DDO CR coordinates/source mismatch"
  fi
  evidence seal "$dir" || die "Cannot seal evidence"
  evidence commit "$dir" "$STATE_DIR/evidence" || die "Cannot commit evidence"
  evidence check "$STATE_DIR/evidence" || die "Evidence commit failed"
}

check_mr_coverage() {
  local live=$1 expected
  expected=$(jq -er '[.items[] | select(.kind == "ManagedResource") | select(.metadata.name | startswith("mr-crd-")) | .metadata.name] | if length > 0 then .[] else error("empty CRD MR inventory") end' "$STATE_DIR/evidence/legacy-manifest.json") || die "Legacy manifest has no required CRD MR inventory"
  local mr
  for mr in $expected; do
    jq -e --arg name "$mr" --arg release "$RELEASE" '[.items[] | select(.metadata.name == $name and .metadata.annotations["meta.helm.sh/release-name"] == $release and .spec.keepObjects == true and .metadata.deletionTimestamp == null)] | length == 1' <<<"$live" >/dev/null || die "Legacy CRD MR missing/unprotected/not release-owned: $mr"
  done
  local crds
  crds=$(mktemp "$STATE_DIR/.crds.XXXXXX")
  kt get crd -o json > "$crds" || die "Cannot recheck expected legacy CRDs"
  evidence crd-coverage "$STATE_DIR/evidence/legacy-crds.json" "$crds" || die "Expected legacy CRD inventory not preserved"
}

assert_protected_mr() {
  local mr=$1 json
  json=$(ks get managedresource "$mr" -o json) || die "Cannot read protection for $mr"
  jq -e --arg release "$RELEASE" '.kind == "ManagedResource" and .metadata.annotations["meta.helm.sh/release-name"] == $release and .spec.keepObjects == true and .metadata.deletionTimestamp == null' <<<"$json" >/dev/null || die "Protection lost/foreign ownership: $mr"
}

recheck_preservation() {
  evidence check "$STATE_DIR/evidence" || die "Immutable evidence changed before uninstall"
  preflight_mr_keepobjects
  local mr gate_mr gate_ns
  for mr in ${PROTECT_MRS:-}; do assert_protected_mr "$mr"; done
  if [[ "$NAMESPACE_CASCADE_GATE" != off ]]; then
    read -r _ gate_mr gate_ns <<< "$NAMESPACE_CASCADE_GATE"
    assert_protected_mr "$gate_mr"
    assert_namespace "$gate_ns"
  fi
}

check_ddo_coordinates() {
  local json=$1 file
  file=$(mktemp "$STATE_DIR/.ddo-health.XXXXXX")
  jq '.items[0]' <<<"$json" > "$file" || die "Invalid DDO Deployment inventory"
  evidence healthy "$file" deployment || die "Installed DDO Deployment not healthy"
  jq -e --slurpfile old "$STATE_DIR/evidence/ddo-controller.json" '.metadata.uid == $old[0].metadata.uid and .metadata.name == $old[0].metadata.name and .metadata.namespace == $old[0].metadata.namespace and (.spec.replicas // 1) == ($old[0].spec.replicas // 1)' "$file" >/dev/null || die "DDO coordinates/UID/original replicas changed since capture"
}

assert_namespace() {
  local json
  json=$(kt get ns "$1" -o json) || die "Namespace state unknown: $1"
  jq -e '.kind == "Namespace" and (.metadata.uid | type == "string" and length > 0) and .metadata.deletionTimestamp == null' <<<"$json" >/dev/null || die "Namespace missing/terminating/malformed: $1"
}

verify_baseline() {
  evidence check "$STATE_DIR/evidence" || die "Required immutable baseline is missing/altered"
  cmp -s "$STATE_DIR/identity.json" "$STATE_DIR/evidence/identity.json" || die "Baseline run identity mismatch"
  if [[ "$NAMESPACE_CASCADE_GATE" != off ]]; then
    local gate_ns ns_uid current_namespace
    read -r _ _ gate_ns <<< "$NAMESPACE_CASCADE_GATE"
    ns_uid=$(jq -er '.metadata.uid' "$STATE_DIR/evidence/protected-namespace.json") || die "Missing protected namespace baseline"
    current_namespace=$(kt get namespace "$gate_ns" -o json) || die "Cannot verify protected namespace"
    jq -e --arg uid "$ns_uid" '.metadata.uid == $uid and .metadata.deletionTimestamp == null' <<<"$current_namespace" >/dev/null || die "Protected namespace replaced/terminating"
  fi
  local kind file name ns uid json group
  for kind in crd ${BASELINE_SNAPSHOT_KINDS_CLUSTER:-} ${BASELINE_SNAPSHOT_KINDS_NS:-}; do
    file="$STATE_DIR/evidence/baseline-$kind.json"
    [[ "$kind" != crd ]] || file="$STATE_DIR/evidence/baseline-crds.json"
    evidence baseline "$file" || die "Required baseline missing/invalid: $kind"
    while IFS=$'\t' read -r name ns uid; do
      [[ -n "$name" ]] || continue
      local args=()
      [[ "$ns" == _cluster ]] || args=(-n "$ns")
      json=$(kt get "$kind" "$name" "${args[@]}" -o json) || die "Baseline object unreadable/missing: $kind/$name"
      jq -e --arg uid "$uid" '.metadata.uid == $uid and .metadata.deletionTimestamp == null' <<<"$json" >/dev/null || die "Baseline object replaced/terminating: $kind/$name"
    done < <(jq -r '.items[] | [.metadata.name, (.metadata.namespace // "_cluster"), .metadata.uid] | @tsv' "$file")
  done
}

assert_legacy_absent() {
  local output
  if output=$(hs status "$RELEASE" 2>&1); then
    die "Legacy release still present/reappeared; DDO handoff/verification blocked"
  fi
  grep -qE '^Error: release: not found$' <<<"$output" || die "Cannot establish legacy release absence: $output"
}

verify_controller_health() {
  local dir owner
  dir=$(mktemp -d "$STATE_DIR/.health.XXXXXX")
  ks get dualdeploymentoperator "$DDO_CR" -o json > "$dir/cr.json" || die "Cannot read DDO CR"
  ks get deployment "$DEPLOY" -o json > "$dir/deploy.json" || die "Cannot read operand Deployment"
  owner=$(jq -er '.expectedOwnerValue' "$STATE_DIR/evidence/readiness.json") || die "Expected owner evidence missing"
  evidence healthy "$dir/cr.json" cr || die "DDO CR pending/stale/terminating"
  evidence healthy "$dir/deploy.json" deployment "$owner" || die "Operand Deployment pending/foreign/terminating"
  jq -e --slurpfile expected "$STATE_DIR/evidence/ddoCRManifest.json" '.spec.source == $expected[0].items[0].spec.source' "$dir/cr.json" >/dev/null || die "Live DDO source differs from reviewed exact source"
}
