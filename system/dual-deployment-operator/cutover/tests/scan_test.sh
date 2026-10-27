#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAKE_BIN="$(mktemp -d)"
PROFILE_DIR="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN" "$PROFILE_DIR"' EXIT

cat >"$FAKE_BIN/u8s" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

kind=object
if [[ "$1" == helm ]]; then
  kind=helm
elif [[ "$*" == *jsonpath=* ]]; then
  kind=ready
fi
if [[ -n "${ATTEMPT_DIR:-}" ]]; then
  count_file="$ATTEMPT_DIR/$kind"
  count=0
  [[ ! -f "$count_file" ]] || read -r count <"$count_file"
  count=$((count + 1))
  printf '%s\n' "$count" >"$count_file"
  if [[ "$kind" == "${FAIL_TARGET:-}" && "$count" -le "${FAIL_FIRST:-0}" ]]; then
    printf '%s\n' "${FAIL_TEXT:-Error: unexpected error when reading response body. Please retry. Original error: http2: client connection lost}" >&2
    exit "${FAIL_RC:-7}"
  fi
  if [[ "$kind" == "${HANG_TARGET:-}" ]]; then
    [[ -z "${HANG_TEXT:-}" ]] || printf '%s\n' "$HANG_TEXT" >&2
    sleep 5
  fi
fi

if [[ "$1" == "helm" ]]; then
  release="${@: -1}"
  case "${FIXTURE_HELM}_${release}" in
    present_*) exit 0 ;;
    absent_*) printf 'Error: release: not found\n' >&2; exit 1 ;;
    error_*) printf 'connection refused\n' >&2; exit 1 ;;
  esac
fi

if [[ "$1" == "kubectl" ]]; then
  [[ "$*" == *"--request-timeout=${PROBE_TIMEOUT}"* ]] || { echo 'kubectl read missing request timeout' >&2; exit 98; }
  previous=''
  jsonpath=false
  for arg in "$@"; do
    if [[ "$previous" == ddo ]]; then
      cr="$arg"
    fi
    [[ "$arg" == -o ]] && jsonpath=true
    previous="$arg"
  done
  case "${FIXTURE_CR}_${cr}" in
    ready_*) printf 'True' ;;
    notready_*) printf 'False' ;;
    readyerror_*)
      if [[ "$jsonpath" == true ]]; then
        printf 'connection refused\n' >&2
        exit 7
      fi
      printf 'True'
      ;;
    absent_*) printf 'Error from server (NotFound): dualdeploymentoperators "%s" not found\n' "$cr" >&2; exit 1 ;;
    missingresource_*) printf 'error: the server doesn\047t have a resource type "ddo"\n' >&2; exit 1 ;;
    error_*) printf 'connection refused\n' >&2; exit 1 ;;
  esac
  exit 0
fi

printf 'unexpected u8s call: %s\n' "$*" >&2
exit 99
EOF
chmod +x "$FAKE_BIN/u8s"

cat >"$PROFILE_DIR/10-first.env" <<'EOF'
RELEASE=first
DDO_CR=first
LEGACY_CHART_DIR=first
ROLLOUT_ORDER=10
EOF
cat >"$PROFILE_DIR/20-second.env" <<'EOF'
RELEASE=second
DDO_CR=second
LEGACY_CHART_DIR=second
ROLLOUT_ORDER=20
EOF

export PATH="$FAKE_BIN:$PATH"
export SEED_CTX=test-seed NAMESPACE=test-ns PROFILE_DIR
export SCAN_RETRIES=3 SCAN_RETRY_DELAY=0 PROBE_TIMEOUT=8s

# shellcheck source=/dev/null
source "$ROOT/scan-ddo-migration.sh"

assert_classification() {
  local helm="$1" cr="$2" expected_state="$3" expected_rc="$4"
  local output rc
  set +e
  output="$(FIXTURE_HELM="$helm" FIXTURE_CR="$cr" classify_chart test test)"
  rc=$?
  set -e
  [[ "$output" == "$expected_state"\ * ]] || { echo "expected $expected_state, got: $output" >&2; exit 1; }
  [[ "$rc" == "$expected_rc" ]] || { echo "expected rc $expected_rc, got $rc" >&2; exit 1; }
}

assert_classification absent ready migrated 0
assert_classification present absent not-migrated 0
assert_classification present ready attention 0
assert_classification absent notready attention 0
assert_classification absent absent attention 0
assert_classification error absent unknown 1
assert_classification absent error unknown 1
assert_classification absent readyerror unknown 1
assert_classification present missingresource unknown 1

METAL_PROFILE="$ROOT/profiles/metal-operator-remote.env"
BOOT_PROFILE="$ROOT/profiles/boot-operator-remote.env"
# shellcheck source=/dev/null
source "$METAL_PROFILE"
[[ "$LEGACY_CHART_DIR" == system/metal-operator-remote ]] || { echo "wrong metal legacy chart dir: $LEGACY_CHART_DIR" >&2; exit 1; }
# shellcheck source=/dev/null
source "$BOOT_PROFILE"
[[ "$LEGACY_CHART_DIR" == system/boot-operator-remote ]] || { echo "wrong boot legacy chart dir: $LEGACY_CHART_DIR" >&2; exit 1; }

output="$(FIXTURE_HELM=present FIXTURE_CR=absent main)"
[[ "$output" == *'next candidate: first'* ]] || { echo "did not nominate first candidate: $output" >&2; exit 1; }
[[ "$output" != *'second |'* ]] || { echo "did not stop after first candidate: $output" >&2; exit 1; }

output="$(FIXTURE_HELM=present FIXTURE_CR=ready main)"
[[ "$output" == *'needs attention: first ('* ]] || { echo "did not report attention: $output" >&2; exit 1; }
[[ "$output" != *'next candidate:'* ]] || { echo "nominated candidate after attention: $output" >&2; exit 1; }

set +e
output="$(FIXTURE_HELM=error FIXTURE_CR=absent main)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "unknown main result must fail" >&2; exit 1; }
[[ "$output" == *'needs attention: first ('* ]] || { echo "did not report unknown: $output" >&2; exit 1; }
[[ "$output" != *'next candidate:'* ]] || { echo "nominated candidate after unknown: $output" >&2; exit 1; }

set +e
output="$(PROFILE_DIR=/nonexistent-profile-dir FIXTURE_HELM=absent FIXTURE_CR=ready main)"
rc=$?
set -e
[[ "$rc" -ne 0 ]] || { echo "missing profiles must fail" >&2; exit 1; }
[[ "$output" != *'all charts migrated'* ]] || { echo "missing profiles reported migration complete: $output" >&2; exit 1; }

echo 'existing scan cases passed (classification, profiles, candidate, attention, unknown, missing profiles)'

export ATTEMPT_DIR="$FAKE_BIN/attempts"
mkdir "$ATTEMPT_DIR"
reset_attempts() { rm -f "$ATTEMPT_DIR/helm" "$ATTEMPT_DIR/object" "$ATTEMPT_DIR/ready"; }
assert_attempts() {
  local count
  read -r count <"$ATTEMPT_DIR/$1"
  [[ "$count" == "$2" ]] || { echo "expected $2 $1 attempts, got $count" >&2; exit 1; }
}

for target in helm object ready; do
  reset_attempts
  if [[ "$target" == helm ]]; then
    FAIL_TARGET="$target" FAIL_FIRST=2 assert_classification present absent not-migrated 0
  else
    FAIL_TARGET="$target" FAIL_FIRST=2 assert_classification absent ready migrated 0
  fi
  assert_attempts "$target" 3
  echo "$target transient failure then success passed (3 attempts)"

  reset_attempts
  FAIL_TARGET="$target" FAIL_FIRST=99 assert_classification absent ready unknown 1
  assert_attempts "$target" 3
  echo "$target exhausted http2 retries fail closed passed (3 attempts)"
done

reset_attempts
assert_classification absent absent attention 0
assert_attempts helm 1
assert_attempts object 1
echo 'genuine Helm/object NotFound immediate absence passed (1 attempt each)'

for target in helm object ready; do
  reset_attempts
  FAIL_TARGET="$target" FAIL_FIRST=99 FAIL_TEXT='Error: Forbidden: permission denied' assert_classification absent ready unknown 1
  assert_attempts "$target" 1
  echo "$target non-retryable error immediate failure passed (1 attempt)"
done

for target in helm object; do
  reset_attempts
  if [[ "$target" == helm ]]; then
    text='Error: release "test" not found'
  else
    text='Error: dualdeploymentoperators "test" not found'
  fi
  FAIL_TARGET="$target" FAIL_FIRST=99 FAIL_TEXT="$text" assert_classification absent absent attention 0
  assert_attempts "$target" 1
  echo "$target quoted NotFound immediate absence passed (1 attempt)"
done

reset_attempts
FAIL_TARGET=ready FAIL_FIRST=99 FAIL_TEXT='Error from server (NotFound): dualdeploymentoperators "test" not found' assert_classification absent ready unknown 1
assert_attempts ready 1
echo 'Ready NotFound fails closed without retry passed (1 attempt)'

reset_attempts
FAIL_TARGET=object FAIL_FIRST=1 FAIL_TEXT='Error: http2: client connection lost; release "test" not found' assert_classification absent ready migrated 0
assert_attempts object 2
echo 'transport error mentioning not found is not absence passed (2 attempts)'

reset_attempts
FAIL_TARGET=object FAIL_FIRST=99 FAIL_TEXT='Error: dualdeploymentoperators "http2-timeout-transport" not found' assert_classification absent absent attention 0
assert_attempts object 1
echo 'NotFound object name containing transport words is not retryable passed (1 attempt)'

reset_attempts
assert_classification absent ready migrated 0
assert_attempts helm 1
assert_attempts object 1
assert_attempts ready 1
echo 'successful reads return immediately passed (1 attempt each); kubectl timeout flags verified'

reset_attempts
SCAN_RETRIES=2 FAIL_TARGET=ready FAIL_FIRST=99 assert_classification absent ready unknown 1
assert_attempts ready 2
echo 'SCAN_RETRIES override passed (2 attempts)'

reset_attempts
PROBE_TIMEOUT=0.1s HANG_TARGET=helm assert_classification absent ready unknown 1
assert_attempts helm 3
echo 'Helm hung read timeout and retry passed (3 attempts)'

check_ambiguous_read() {
  local target="$1" label="$2" output rc count
  reset_attempts
  if output=$(FIXTURE_HELM=absent FIXTURE_CR=ready classify_chart test test); then
    rc=0
  else
    rc=$?
  fi
  read -r count <"$ATTEMPT_DIR/$target"
  if [[ "$output" != 'unknown '* || "$rc" != 1 || "$count" != 3 ]]; then
    printf '%s FAILED: expected unknown/rc=1/3 attempts; got %s/rc=%s/%s attempts\n' "$label" "$output" "$rc" "$count" >&2
    return 1
  fi
  printf '%s passed (unknown, rc=1, 3 attempts)\n' "$label"
}

regressions_failed=0
if ! PROBE_TIMEOUT=0.1s HANG_TARGET=helm HANG_TEXT='Error: release: not found' check_ambiguous_read helm 'P0-1 actual Helm timeout after NotFound'; then
  regressions_failed=1
fi
if ! FAIL_TARGET=helm FAIL_FIRST=99 FAIL_RC=137 FAIL_TEXT='Error: release: not found' check_ambiguous_read helm 'P0-1 Helm termination status 137 after NotFound'; then
  regressions_failed=1
fi
if ! FAIL_TARGET=helm FAIL_FIRST=99 FAIL_TEXT=$'Error: release: not found\nError: Helm read timed out' check_ambiguous_read helm 'P0-1 combined NotFound/timeout diagnostics'; then
  regressions_failed=1
fi
if ! FAIL_TARGET=object FAIL_FIRST=99 FAIL_TEXT='Error: Get "https://seed": transport failed; object "test" not found' check_ambiguous_read object 'P0-2 transport failure after a quoted URL'; then
  regressions_failed=1
fi
[[ "$regressions_failed" == 0 ]] || exit 1

reset_attempts
FAIL_TARGET=object FAIL_FIRST=99 FAIL_TEXT='Error from server (NotFound): dualdeploymentoperators "http2-timeout-transport" not found' assert_classification absent absent attention 0
assert_attempts object 1
echo 'server NotFound with transport words only in object name passed (1 attempt)'

reset_attempts
FAIL_TARGET=object FAIL_FIRST=99 FAIL_TEXT=$'Error from server (NotFound): dualdeploymentoperators "test" not found\nError: transport failed' assert_classification absent ready unknown 1
assert_attempts object 3
echo 'server NotFound combined with transport diagnostics fails closed passed (3 attempts)'

reset_attempts
FAIL_TARGET=object FAIL_FIRST=99 FAIL_TEXT='Error from server (NotFound): transport failed; object "test" not found' assert_classification absent ready unknown 1
assert_attempts object 3
echo 'malformed server NotFound containing transport failure fails closed passed (3 attempts)'

reset_attempts
FAIL_TARGET=helm FAIL_FIRST=99 FAIL_TEXT=$'Error: release: not found\nError: Forbidden: permission denied' assert_classification absent ready unknown 1
assert_attempts helm 1
echo 'Helm NotFound combined with non-retryable diagnostics fails closed passed (1 attempt)'

echo 'scan tests passed'
