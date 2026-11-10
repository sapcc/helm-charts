#!/usr/bin/env bash
# POC test: Lane A — webhook remote-sourcing
#
# Verifies that:
#   kustomize build shoot-poc/
#   + simulated DDO rewriteWebhookURL(urlPrefix=https://ipam-capi-remote-webhook-service:443)
#   + simulated DDO filterKinds([Service])
# produces output byte-for-byte equivalent to the committed shoot/webhooks.yaml (url-form).
#
# The hand-authored shoot/webhooks.yaml uses url: form already (DDO-transformed state).
# shoot-poc/ fetches the upstream service-based clientConfig; DDO would convert it.
# This test proves the full roundtrip is equivalent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"

command -v kustomize >/dev/null || { echo "FAIL: kustomize not found in PATH"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 not found in PATH"; exit 1; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ipam-poc-webhook.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== POC Lane A: webhook remote-sourcing ==="
echo ""

# Step 1: kustomize build shoot-poc/
echo "[1/3] Building shoot-poc overlay..."
kustomize build "$OVERLAY_DIR/shoot-poc" > "$WORK_DIR/shoot-poc-raw.yaml"
echo "      Done."

# Step 2+3: simulate DDO rewriteWebhookURL + filterKinds, then assert equality with
# the committed shoot render's webhook objects.
echo "[2/3] Simulating DDO transforms (rewriteWebhookURL + filterKinds[Service])..."
echo "[3/3] Asserting simulated result == committed shoot/webhooks.yaml output..."
echo ""

PYTHONDONTWRITEBYTECODE=1 python3 - "$WORK_DIR/shoot-poc-raw.yaml" "$OVERLAY_DIR" <<'PY'
import sys
import yaml
import difflib

poc_file = sys.argv[1]
overlay_dir = sys.argv[2]

# ── Simulate DDO rewriteWebhookURL ──────────────────────────────────────────
# DDO transform: urlPrefix=https://ipam-capi-remote-webhook-service:443
# For each MWC/VWC webhook clientConfig:
#   if url already set -> no-op
#   else: url = urlPrefix + service.path, delete service block
URL_PREFIX = "https://ipam-capi-remote-webhook-service:443"

def rewrite_webhook_url(docs):
    for d in docs:
        if d is None:
            continue
        if d.get('kind') in ('MutatingWebhookConfiguration', 'ValidatingWebhookConfiguration'):
            for wh in d.get('webhooks', []):
                cc = wh.get('clientConfig', {})
                if 'url' in cc:
                    # Already has url — no-op (preserves caBundle if present)
                    pass
                elif 'service' in cc:
                    svc = cc.pop('service')
                    cc['url'] = URL_PREFIX + svc['path']
    return docs

# ── Simulate DDO filterKinds ─────────────────────────────────────────────────
# Drops any document whose kind is in the filter list.
FILTER_KINDS = {'Service'}

def filter_kinds(docs):
    return [d for d in docs if d is not None and d.get('kind') not in FILTER_KINDS]

# ── Load POC render ──────────────────────────────────────────────────────────
with open(poc_file) as f:
    poc_docs = list(yaml.safe_load_all(f))

# Apply transforms
poc_docs = rewrite_webhook_url(poc_docs)
poc_docs = filter_kinds(poc_docs)

# ── Load committed shoot render (reference) ──────────────────────────────────
# We run kustomize build shoot/ and compare only the webhook objects.
# The reference is the webhook objects from the CURRENT committed shoot render.
import subprocess, os
result = subprocess.run(
    ['kustomize', 'build', overlay_dir + '/shoot'],
    capture_output=True, text=True
)
if result.returncode != 0:
    print(f"FAIL: kustomize build shoot failed:\n{result.stderr}")
    sys.exit(1)

current_docs = list(yaml.safe_load_all(result.stdout))

# ── Extract webhook objects for comparison ───────────────────────────────────
WEBHOOK_KINDS = {'MutatingWebhookConfiguration', 'ValidatingWebhookConfiguration'}

def webhook_index(docs):
    return {(d['kind'], d['metadata']['name']): d
            for d in docs if d is not None and d.get('kind') in WEBHOOK_KINDS}

poc_webhooks = webhook_index(poc_docs)
cur_webhooks = webhook_index(current_docs)

# ── Assert equivalence ───────────────────────────────────────────────────────
failed = False

if poc_webhooks.keys() != cur_webhooks.keys():
    print("FAIL: webhook object inventory differs")
    print(f"  POC:     {sorted(poc_webhooks.keys())}")
    print(f"  Current: {sorted(cur_webhooks.keys())}")
    failed = True
else:
    print(f"PASS: webhook inventory matches ({len(poc_webhooks)} objects)")

for key in sorted(poc_webhooks.keys()):
    poc_str = yaml.dump(poc_webhooks[key], default_flow_style=False, sort_keys=True)
    cur_str = yaml.dump(cur_webhooks[key], default_flow_style=False, sort_keys=True)
    if poc_str == cur_str:
        print(f"PASS: {key[0]} {key[1]} — byte-for-byte match after simulated DDO transforms")
    else:
        print(f"FAIL: {key[0]} {key[1]} — mismatch after simulated transforms")
        diff = list(difflib.unified_diff(
            cur_str.splitlines(keepends=True),
            poc_str.splitlines(keepends=True),
            fromfile='current (committed)',
            tofile='poc (after sim transforms)'
        ))
        print(''.join(diff[:60]))
        failed = True

# ── Assert Service was filtered ──────────────────────────────────────────────
poc_services = [d for d in poc_docs if d is not None and d.get('kind') == 'Service'
                and d['metadata']['name'] == 'webhook-service']
if not poc_services:
    print("PASS: upstream webhook-service (Service) correctly filtered by simulated filterKinds")
else:
    print("FAIL: webhook-service (Service) still present after filterKinds simulation")
    failed = True

print("")
if not failed:
    print("=== POC Lane A: ALL CHECKS PASSED ===")
    sys.exit(0)
else:
    print("=== POC Lane A: SOME CHECKS FAILED ===")
    sys.exit(1)
PY
