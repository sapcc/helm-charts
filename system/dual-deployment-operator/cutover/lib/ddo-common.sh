#!/usr/bin/env bash
# ddo-common.sh — shared, side-effect-free helpers for the DDO cutover tooling.
#
# CONTRACT: this file defines FUNCTIONS ONLY. It must be safe to `source` from
# any script (and from tests that source a consumer script): no `set`, no traps,
# no argument parsing, no top-level output, no global assignments, and no
# discovery calls at source time. Defaults are resolved INSIDE functions via
# ${VAR:-default} so a consumer can override them via the environment.
#
# Shared by:
#   - scan-ddo-migration.sh   (Layer 1, read-only fleet scanner)
#   - cutover-ddo.sh          (Layer 2, per-chart cutover engine)
#
# The DDO CR and the legacy Helm release both live on the SEED cluster, in the
# shoot control-plane namespace `shoot--cp--<shoot>`. The shoot/target cluster
# (named like m-qa-de-200) only hosts the managed operand workloads and does
# NOT serve the dualdeploymentoperator CRD. Callers therefore discover the seed
# context that actually hosts `shoot--cp--<shoot>` rather than assuming the
# shoot name is the seed context.

# probe_ns <context> <namespace>
# Returns 0 if <context> hosts <namespace>, non-zero otherwise. Bounded by a
# per-probe kubectl --request-timeout so a single unreachable context does not
# dominate the run. Note: --request-timeout bounds the API request, not the
# whole process (auth/login can still add latency); it is a best-effort bound,
# not a hard whole-process deadline.
probe_ns() {
  local ctx="$1" ns="$2"
  u8s kubectl --context "$ctx" get ns "$ns" --no-headers \
    --request-timeout="${PROBE_TIMEOUT:-8s}" >/dev/null 2>&1
}

# discover_seed <cluster> <namespace>
# Finds the seed kubectl context that hosts <namespace> and assigns it to the
# caller's SEED_CTX variable. Prints progress to stderr. Returns 0 on success,
# non-zero on failure — NEVER exits, so it is safe to call from a sourced
# context. MUST NOT be called inside command substitution (the SEED_CTX
# assignment would be lost in the subshell).
#
# If SEED_CTX is already set, discovery is skipped (honours an explicit
# --seed-context / env override).
#
# Probe order (most likely first, so one dead cluster can't stall the run):
#   tier 1 — exact-cluster-shaped guesses: <prefix>-<base> (same numeric suffix)
#   tier 2 — region-wide guesses:          <prefix>-<region>-1
#   tier 3 — any other context mentioning the region (same family)
#   tier 4 — everything else (full scan, deterministic order)
# `-new-tenant` contexts are DEPRIORITISED (ranked last within their tier), not
# discarded: some landscapes require a tenant-scoped context as the seed.
#
# Known seed prefixes (ranking only, never filtering): a-* standard SAP CC seed,
# g-* garden-named seed, rt-* runtime seed. Override via SEED_PREFIXES.
discover_seed() {
  local cluster="$1" ns="$2"
  if [[ -n "${SEED_CTX:-}" ]]; then
    printf 'using provided seed context: %s\n' "$SEED_CTX" >&2
    return 0
  fi

  local seed_prefixes="${SEED_PREFIXES:-a g rt}"
  printf 'discovering seed context for namespace %s (probe timeout %s) ...\n' \
    "$ns" "${PROBE_TIMEOUT:-8s}" >&2

  local all
  # Deprioritise `-new-tenant` duplicates by sorting them to the end rather than
  # dropping them (they can be the only valid seed in some landscapes).
  all=$(u8s kubectl config get-contexts -o name 2>/dev/null \
        | awk '{ print ($0 ~ /-new-tenant$/ ? 1 : 0), $0 }' \
        | sort -s -k1,1n | cut -d' ' -f2- || true)
  if [[ -z "$all" ]]; then
    printf 'no kubectl contexts found (run "u8s sync"?)\n' >&2
    return 1
  fi

  # Derive a region key from the cluster name: strip a single leading known
  # prefix and any trailing numeric suffix, e.g.
  #   m-qa-de-200 -> qa-de ; m-qa-de-1 -> qa-de ; eu-de-1 -> eu-de.
  local p g c base region
  base="$cluster"
  for p in $seed_prefixes m; do
    if [[ "$base" == "$p-"* ]]; then
      base="${base#"$p"-}"
      break
    fi
  done
  region="$(printf '%s' "$base" | sed -E 's/-?[0-9]+$//')"

  local ranked="" tier1="" tier2=""
  for p in $seed_prefixes; do
    tier1+=" $p-$base"
    [[ "$base" != "$region" ]] && tier2+=" $p-$region-1"
  done

  # Tiers 1 + 2: concrete guesses, deduped against the real context list.
  for g in $tier1 $tier2; do
    for c in $all; do
      if [[ "$c" == "$g" ]]; then
        case " $ranked " in *" $c "*) ;; *) ranked+=" $c" ;; esac
      fi
    done
  done
  # Tier 3: any remaining context mentioning the region.
  for c in $all; do
    case " $ranked " in *" $c "*) continue ;; esac
    case "$c" in *"$region"*) ranked+=" $c" ;; esac
  done
  # Tier 4: everything else (preserves the deprioritised `-new-tenant` order).
  for c in $all; do
    case " $ranked " in *" $c "*) continue ;; esac
    ranked+=" $c"
  done

  local ctx
  for ctx in $ranked; do
    printf '    probing %-30s ... ' "$ctx" >&2
    if probe_ns "$ctx" "$ns"; then
      printf 'HIT\n' >&2
      SEED_CTX="$ctx"
      printf 'seed context = %s (hosts %s)\n' "$SEED_CTX" "$ns" >&2
      return 0
    fi
    printf 'no\n' >&2
  done

  printf 'could not auto-discover a seed hosting %s; pass --seed-context (or set SEED_CTX)\n' \
    "$ns" >&2
  return 1
}
