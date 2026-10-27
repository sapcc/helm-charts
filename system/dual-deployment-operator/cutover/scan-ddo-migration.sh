#!/usr/bin/env bash
# Read-only migration scanner.  State-read failures are never candidates.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${PROFILE_DIR:-$SCRIPT_DIR/profiles}"

# Maximum read attempts (including the first): 3; delay: 2s; timeout: 8s.
# Override with SCAN_RETRIES, SCAN_RETRY_DELAY (seconds), and PROBE_TIMEOUT.
SCAN_RETRIES="${SCAN_RETRIES:-3}"
SCAN_RETRY_DELAY="${SCAN_RETRY_DELAY:-2}"
PROBE_TIMEOUT="${PROBE_TIMEOUT:-8s}"

retryable_read_error() {
  grep -qiE 'http2([:[:space:]]|$)|client connection lost|please retry|timeout|timed out|context deadline exceeded|connection (refused|reset|closed|lost)|transport|TLS handshake|unexpected EOF|i/o timeout|no route to host|network is unreachable|temporary failure in name resolution|dial (tcp|udp)' <<<"$1"
}

object_not_found() {
  local pattern='^(Error from server \(NotFound\): |[Ee]rror: )([[:alnum:]_.-]+) "([^" ]+)" not found$'
  local diagnostic
  # Require one complete typed object-absence diagnostic, not a matching line
  # inside mixed stderr. Remove only the object NAME before checking transport
  # text; quoted URLs or other diagnostics must never hide a read failure.
  [[ "$1" != *$'\n'* && "$1" =~ $pattern ]] || return 1
  diagnostic="${BASH_REMATCH[1]}${BASH_REMATCH[2]} \"\" not found"
  ! retryable_read_error "$diagnostic"
}

# $1 = wrapper function, $2.. = command args. Echoes found|absent|error, never dies.
obj_state() {
  local ctxfn="$1" err rc attempt
  shift
  for ((attempt=1; attempt<=SCAN_RETRIES; attempt++)); do
    if err=$("$ctxfn" "$@" 2>&1 >/dev/null); then
      echo found
      return 0
    else
      rc=$?
    fi
    # API discovery errors ("doesn't have a resource type") are not absence.
    if object_not_found "$err"; then
      echo absent
      return 0
    fi
    if ! retryable_read_error "$err" || ((attempt == SCAN_RETRIES)); then
      break
    fi
    sleep "$SCAN_RETRY_DELAY"
  done
  echo error
  return 0
}

ks() { u8s kubectl --context "$SEED_CTX" -n "$NAMESPACE" --request-timeout="$PROBE_TIMEOUT" "$@"; }
hs() {
  local timer rc
  # Helm status has no request-timeout flag. GNU timeout bounds the entire read,
  # including child processes; gtimeout supports macOS coreutils installations.
  if command -v timeout >/dev/null 2>&1; then
    timer=timeout
  elif command -v gtimeout >/dev/null 2>&1; then
    timer=gtimeout
  else
    echo 'Error: required GNU coreutils timer is unavailable' >&2
    return 1
  fi
  if "$timer" --kill-after=1s "$PROBE_TIMEOUT" u8s helm --kube-context "$SEED_CTX" -n "$NAMESPACE" "$@"; then
    return 0
  else
    rc=$?
  fi
  if [[ "$rc" == 124 || "$rc" == 137 ]]; then
    echo 'Error: Helm read timed out' >&2
  fi
  return "$rc"
}

helm_state() {
  local release="$1" err rc attempt
  local not_found='^Error: release: not found$|^Error: release "[^" ]+" not found$'
  for ((attempt=1; attempt<=SCAN_RETRIES; attempt++)); do
    if err=$(hs status "$release" 2>&1 >/dev/null); then
      echo found
      return 0
    else
      rc=$?
    fi
    # Timeout/termination invalidates even an otherwise typed NotFound. Only
    # one clean release-lookup diagnostic can prove absence; mixed stderr cannot.
    if [[ "$rc" == 124 || "$rc" == 137 ]]; then
      : # Retry the failed read below, without considering absence text.
    elif [[ "$err" != *$'\n'* && "$err" =~ $not_found ]]; then
      echo absent
      return 0
    fi
    if ((attempt == SCAN_RETRIES)); then
      break
    fi
    if [[ "$rc" != 124 && "$rc" != 137 ]] && ! retryable_read_error "$err"; then
      break
    fi
    sleep "$SCAN_RETRY_DELAY"
  done
  echo error
}

ready_state() {
  local cr="$1" value err text rc=1 attempt
  err="$(mktemp)"
  for ((attempt=1; attempt<=SCAN_RETRIES; attempt++)); do
    if value=$(ks get ddo "$cr" -o 'jsonpath={.status.conditions[?(@.type=="Ready")].status}' 2>"$err"); then
      rm -f "$err"
      printf '%s\n' "$value"
      return 0
    else
      rc=$?
    fi
    text="$(<"$err")"
    if object_not_found "$text" || ! retryable_read_error "$text" || ((attempt == SCAN_RETRIES)); then
      break
    fi
    sleep "$SCAN_RETRY_DELAY"
  done
  rm -f "$err"
  return "$rc"
}

# $1 = legacy release; $2 = DDO CR. Echoes "state reason".
classify_chart() {
  local release="$1" cr="$2" legacy ddo ready
  legacy="$(helm_state "$release")"
  ddo="$(obj_state ks get ddo "$cr")"

  if [[ "$legacy" == error || "$ddo" == error ]]; then
    echo 'unknown state read failed'
    return 1
  fi

  if [[ "$legacy" == found && "$ddo" == absent ]]; then
    echo 'not-migrated legacy release present; DDO CR absent'
    return 0
  fi
  if [[ "$legacy" == found && "$ddo" == found ]]; then
    echo 'attention legacy release and DDO CR both present'
    return 0
  fi
  if [[ "$legacy" == absent && "$ddo" == absent ]]; then
    echo 'attention legacy release and DDO CR both absent'
    return 0
  fi

  if ! ready="$(ready_state "$cr")"; then
    echo 'unknown DDO Ready read failed'
    return 1
  fi
  if [[ "$ready" == True ]]; then
    echo 'migrated DDO CR Ready=True; legacy release absent'
  else
    echo 'attention DDO CR Ready is not True'
  fi
}

usage() {
  echo "usage: $0 --cluster <cluster>" >&2
}

main() {
  local cluster='' profile output state detail rc order
  local -a profiles
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cluster) cluster="${2:-}"; shift 2 ;;
      --help|-h) usage; return 0 ;;
      *) usage; return 2 ;;
    esac
  done

  # Explicit environment values let operators supply discovered seed coordinates.
  # For the common case, u8s context and the seed control-plane namespace match
  # the requested cluster name.
  if [[ -n "$cluster" ]]; then
    SEED_CTX="${SEED_CTX:-$cluster}"
    NAMESPACE="${NAMESPACE:-shoot--cp--$cluster}"
  fi
  : "${SEED_CTX:?set SEED_CTX or pass --cluster}"
  : "${NAMESPACE:?set NAMESPACE or pass --cluster}"

  if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "error: profile directory not found: $PROFILE_DIR" >&2
    return 1
  fi
  shopt -s nullglob
  profiles=("$PROFILE_DIR"/*.env)
  shopt -u nullglob
  if [[ ${#profiles[@]} -eq 0 ]]; then
    echo "error: no profiles found in $PROFILE_DIR" >&2
    return 1
  fi
  for profile in "${profiles[@]}"; do
    if ! bash -c 'source "$1"; : "${RELEASE:?}" "${DDO_CR:?}" "${ROLLOUT_ORDER:?}"' _ "$profile"; then
      echo "error: invalid profile: $profile" >&2
      return 1
    fi
  done
  printf 'chart | state | detail\n'
  while IFS= read -r profile; do
    unset RELEASE DDO_CR LEGACY_CHART_DIR ROLLOUT_ORDER
    # shellcheck source=/dev/null
    source "$profile"
    set +e
    output="$(classify_chart "$RELEASE" "$DDO_CR")"
    rc=$?
    set -e
    state="${output%% *}"
    detail="${output#* }"
    printf '%s | %s | %s\n' "$RELEASE" "$state" "$detail"
    case "$state" in
      migrated) ;;
      not-migrated) echo "next candidate: $RELEASE"; return 0 ;;
      attention|unknown) echo "needs attention: $RELEASE ($detail)"; return "$rc" ;;
    esac
  done < <(for profile in "${profiles[@]}"; do
    order=$(bash -c 'source "$1"; printf "%s" "$ROLLOUT_ORDER"' _ "$profile")
    printf '%s %s\n' "$order" "$profile"
  done | sort -n | cut -d' ' -f2-)
  echo 'all charts migrated'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
