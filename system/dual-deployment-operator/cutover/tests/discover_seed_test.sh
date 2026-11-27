#!/usr/bin/env bash
# discover_seed_test.sh — tests for the shared seed-discovery library
# (lib/ddo-common.sh). Exercises probe_ns ranking, SEED_CTX override, failure
# semantics (return, never exit), and -new-tenant deprioritisation.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAKE_BIN="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN"' EXIT

# Fake u8s:
#   - `kubectl config get-contexts -o name` emits $FAKE_CONTEXTS (newline-sep).
#   - `kubectl --context <c> get ns <ns> ...` succeeds iff <c> == $HIT_CTX.
#   - every probed context is appended to $PROBE_LOG so we can assert order.
cat >"$FAKE_BIN/u8s" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
[[ "$1" == kubectl ]] || { echo "unexpected u8s call: $*" >&2; exit 99; }
shift
if [[ "$1" == config && "$2" == get-contexts ]]; then
  printf '%s\n' "${FAKE_CONTEXTS:-}"
  exit 0
fi
# Parse `--context <c> get ns <ns> ...`
ctx=''; want_ctx=false
for a in "$@"; do
  if $want_ctx; then ctx="$a"; want_ctx=false; continue; fi
  [[ "$a" == --context ]] && want_ctx=true
done
[[ -n "${PROBE_LOG:-}" ]] && printf '%s\n' "$ctx" >>"$PROBE_LOG"
[[ "$ctx" == "${HIT_CTX:-__none__}" ]] && exit 0
echo 'Error from server (NotFound)' >&2
exit 1
EOF
chmod +x "$FAKE_BIN/u8s"
export PATH="$FAKE_BIN:$PATH"
export PROBE_TIMEOUT=1s

fail() { echo "FAIL: $*" >&2; exit 1; }

# Initialise the probe log BEFORE sourcing so a source-time probe would be
# caught (the "no probes on source" assertion below would otherwise be blind).
export PROBE_LOG="$FAKE_BIN/plog"
: >"$PROBE_LOG"

# shellcheck source=../lib/ddo-common.sh
source "$ROOT/lib/ddo-common.sh"

# 1. Sourcing performs no probes on its own.
[[ ! -s "$PROBE_LOG" ]] || fail "sourcing the lib probed contexts: $(tr '\n' ' ' <"$PROBE_LOG")"
echo "pass: sourcing performs no probes"

# 2. Explicit SEED_CTX bypasses discovery entirely (no probes).
: >"$PROBE_LOG"
SEED_CTX=preset-seed
FAKE_CONTEXTS=$'a-qa-de-200\nm-qa-de-200' HIT_CTX=a-qa-de-200 \
  discover_seed m-qa-de-200 shoot--cp--m-qa-de-200 || fail "preset seed returned nonzero"
[[ "$SEED_CTX" == preset-seed ]] || fail "preset SEED_CTX was overwritten: $SEED_CTX"
[[ ! -s "$PROBE_LOG" ]] || fail "preset SEED_CTX still probed: $(tr '\n' ' ' <"$PROBE_LOG")"
unset SEED_CTX
echo "pass: explicit SEED_CTX bypasses discovery"

# 3. Shoot resolves to the region-ranked seed; a-qa-de-200 is probed before the
#    unrelated shoot/other-region contexts.
: >"$PROBE_LOG"
unset SEED_CTX
FAKE_CONTEXTS=$'m-qa-de-200\nz-eu-de-1\na-qa-de-200' HIT_CTX=a-qa-de-200 \
  discover_seed m-qa-de-200 shoot--cp--m-qa-de-200 || fail "discovery failed to resolve seed"
[[ "${SEED_CTX:-}" == a-qa-de-200 ]] || fail "resolved wrong seed: ${SEED_CTX:-<unset>}"
# a-qa-de-200 (tier-1 guess) must be the FIRST probe.
head -1 "$PROBE_LOG" | grep -qx 'a-qa-de-200' || fail "region-ranked seed not probed first: $(tr '\n' ' ' <"$PROBE_LOG")"
unset SEED_CTX
echo "pass: shoot resolves to region-ranked seed, probed first"

# 4. Discovery failure returns non-zero and does NOT kill this (sourced) shell.
: >"$PROBE_LOG"
unset SEED_CTX
rc=0
FAKE_CONTEXTS=$'m-qa-de-200\nz-eu-de-1' HIT_CTX=__none__ \
  discover_seed m-qa-de-200 shoot--cp--m-qa-de-200 || rc=$?
[[ "$rc" -ne 0 ]] || fail "discovery failure did not return non-zero"
[[ -z "${SEED_CTX:-}" ]] || fail "SEED_CTX set despite failure: $SEED_CTX"
echo "pass: discovery failure returns non-zero without exiting the shell"

# 5. A -new-tenant context is still discoverable (deprioritised, not dropped).
#    Use two SAME-REGION (tier-3) contexts so region ranking is a tie and the
#    only differentiator is -new-tenant deprioritisation. The non-tenant peer
#    must be probed first; the tenant context is still reached (not dropped).
#    Raw list order deliberately lists the tenant context FIRST to prove the
#    deprioritisation re-sort actually moves it below its peer.
: >"$PROBE_LOG"
unset SEED_CTX
FAKE_CONTEXTS=$'mgmt-eu-de-1-new-tenant\ng-eu-de-9' HIT_CTX=mgmt-eu-de-1-new-tenant \
  discover_seed eu-de-1 shoot--cp--eu-de-1 || fail "tenant-only seed not discovered"
[[ "${SEED_CTX:-}" == mgmt-eu-de-1-new-tenant ]] || fail "did not discover tenant seed: ${SEED_CTX:-<unset>}"
# g-eu-de-9 (non-tenant, same region) must be probed before the -new-tenant
# context, even though it appears LATER in the raw context list.
order="$(tr '\n' ' ' <"$PROBE_LOG")"
[[ "$order" == 'g-eu-de-9 mgmt-eu-de-1-new-tenant '* ]] \
  || fail "tenant context not deprioritised below same-region peers; probe order: $order"
unset SEED_CTX
echo "pass: -new-tenant context deprioritised but still discoverable"

echo 'discover_seed tests passed'
