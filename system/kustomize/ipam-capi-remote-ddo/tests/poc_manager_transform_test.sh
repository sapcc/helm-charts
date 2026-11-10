#!/usr/bin/env bash
# POC test: Lane B — config/manager remote-sourcing
#
# Verifies that:
#   kustomize build seed-poc/
#   + simulated DDO filterKinds([Namespace, ConfigMap]) for upstream extras
# produces a Deployment byte-for-byte equal to the committed seed render's Deployment,
# and that all other shared resources also match exactly.
#
# The seed-poc/ overlay fetches upstream config/manager (which ships Namespace "system"
# and ConfigMap "manager-config" as extras). DDO filterKinds would drop these at deploy.
# This test proves the remote base + SAP strategic-merge patch + simulated filterKinds
# reproduces today's committed seed output for all shared resources.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"

command -v kustomize >/dev/null || { echo "FAIL: kustomize not found in PATH"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 not found in PATH"; exit 1; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ipam-poc-manager.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== POC Lane B: config/manager remote-sourcing ==="
echo ""

# Step 1: kustomize build seed-poc/
echo "[1/3] Building seed-poc overlay..."
kustomize build "$OVERLAY_DIR/seed-poc" > "$WORK_DIR/seed-poc-raw.yaml"
echo "      Done."

# Step 2+3: simulate DDO filterKinds, then assert equality with committed seed render.
echo "[2/3] Simulating DDO transforms (filterKinds[Namespace + upstream manager-config ConfigMap])..."
echo "[3/3] Asserting simulated result == committed seed render for all shared resources..."
echo ""

PYTHONDONTWRITEBYTECODE=1 python3 - "$WORK_DIR/seed-poc-raw.yaml" "$OVERLAY_DIR" <<'PY'
import sys
import yaml
import difflib
import subprocess

poc_file = sys.argv[1]
overlay_dir = sys.argv[2]

# ── Simulate DDO filterKinds ─────────────────────────────────────────────────
# DDO drops Namespace (upstream ships Namespace "system" we don't want).
# Also drops the upstream ConfigMap "manager-config" (produced by the upstream
# configMapGenerator; our overlay uses "ipam-capi-manager-config" instead).
# In the real deploy, DDO filterKinds handles both.
FILTER_KINDS = {'Namespace'}
FILTER_NAME_KIND = {('ConfigMap', 'manager-config')}  # upstream configMapGenerator artifact

def filter_extras(docs):
    result = []
    for d in docs:
        if d is None:
            continue
        if d.get('kind') in FILTER_KINDS:
            continue
        if (d.get('kind'), d['metadata']['name']) in FILTER_NAME_KIND:
            continue
        result.append(d)
    return result

# ── Load POC render ──────────────────────────────────────────────────────────
with open(poc_file) as f:
    poc_docs = list(yaml.safe_load_all(f))

poc_docs = filter_extras(poc_docs)

# ── Load committed seed render (reference) ───────────────────────────────────
result = subprocess.run(
    ['kustomize', 'build', overlay_dir + '/seed'],
    capture_output=True, text=True
)
if result.returncode != 0:
    print(f"FAIL: kustomize build seed failed:\n{result.stderr}")
    sys.exit(1)

current_docs = [d for d in yaml.safe_load_all(result.stdout) if d is not None]

# ── Index by (kind, name) ────────────────────────────────────────────────────
def index(docs):
    return {(d['kind'], d['metadata']['name']): d for d in docs}

poc_idx = index(poc_docs)
cur_idx = index(current_docs)

# ── Assert inventory ─────────────────────────────────────────────────────────
failed = False

poc_only = poc_idx.keys() - cur_idx.keys()
cur_only = cur_idx.keys() - poc_idx.keys()

if poc_only:
    print("FAIL: resources in POC but not in committed seed (should be filtered):")
    for k in sorted(poc_only):
        print(f"  + {k[0]} {k[1]}")
    failed = True

if cur_only:
    print("FAIL: resources in committed seed but missing from POC:")
    for k in sorted(cur_only):
        print(f"  - {k[0]} {k[1]}")
    failed = True

if not poc_only and not cur_only:
    print(f"PASS: resource inventory matches ({len(poc_idx)} objects)")

# ── Assert per-resource equality ─────────────────────────────────────────────
for key in sorted(poc_idx.keys() & cur_idx.keys()):
    poc_str = yaml.dump(poc_idx[key], default_flow_style=False, sort_keys=True)
    cur_str = yaml.dump(cur_idx[key], default_flow_style=False, sort_keys=True)
    if poc_str == cur_str:
        print(f"PASS: {key[0]} {key[1]} — byte-for-byte match")
    else:
        print(f"FAIL: {key[0]} {key[1]} — mismatch")
        diff = list(difflib.unified_diff(
            cur_str.splitlines(keepends=True),
            poc_str.splitlines(keepends=True),
            fromfile='current (committed)',
            tofile='poc (after simulated filterKinds)'
        ))
        print(''.join(diff[:80]))
        failed = True

print("")
if not failed:
    print("=== POC Lane B: ALL CHECKS PASSED ===")
    sys.exit(0)
else:
    print("=== POC Lane B: SOME CHECKS FAILED ===")
    sys.exit(1)
PY
