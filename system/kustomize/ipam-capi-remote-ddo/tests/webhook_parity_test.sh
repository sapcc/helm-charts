#!/usr/bin/env bash
# Test: shoot render + simulated DDO rewriteWebhookURL produces url-form webhook configs
# matching the expected contract (8 webhooks, correct names, correct URLs, injector label).
#
# Background: shoot/kustomization.yaml sources webhooks from the upstream config/webhook
# directory (service-form clientConfig) and deletes the upstream webhook-service (Service)
# via a targeted $patch:delete kustomize patch.  DDO applies one transform at deploy time:
#   rewriteWebhookURL(urlPrefix=https://ipam-capi-remote-webhook-service:443)
#     -> converts service{name,path} -> url = urlPrefix + path, deletes service block
# This test:
#   (a) asserts the plain kustomize build has no webhook-service Service (overlay deleted it)
#       AND retains the shoot metrics Service (guard against over-deletion)
#   (b) simulates DDO rewriteWebhookURL and asserts the full 8-webhook contract
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"

command -v kustomize >/dev/null || { echo "FAIL: kustomize not found in PATH"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL: python3 not found in PATH"; exit 1; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ipam-webhook-parity.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "=== Webhook parity test (remote-sourced + simulated DDO rewriteWebhookURL) ==="
echo ""

# Step 1: kustomize build shoot/
echo "[1/2] Building shoot overlay..."
kustomize build "$OVERLAY_DIR/shoot" > "$WORK_DIR/shoot-raw.yaml"
echo "      Done."

# Step 2: assert Service inventory on raw build, simulate rewriteWebhookURL, assert webhooks.
echo "[2/2] Asserting Service inventory and webhook contract..."
echo ""

PYTHONDONTWRITEBYTECODE=1 python3 - "$WORK_DIR/shoot-raw.yaml" <<'PY'
import sys
import yaml

raw_file = sys.argv[1]

# ── Load raw shoot render ─────────────────────────────────────────────────────
with open(raw_file) as f:
    docs = list(yaml.safe_load_all(f))

WEBHOOK_KINDS = {'MutatingWebhookConfiguration', 'ValidatingWebhookConfiguration'}
failed = 0

# ── Assert Service inventory on RAW build (before any simulation) ─────────────
# The upstream webhook-service must be absent (deleted by overlay $patch:delete).
# The shoot metrics Service must be present (guard against over-deletion).
raw_services = {d['metadata']['name']: d for d in docs
                if d and d.get('kind') == 'Service'}

if 'webhook-service' not in raw_services:
    print("PASS: upstream webhook-service (Service) absent from raw build — overlay deleted it")
else:
    print("FAIL: webhook-service (Service) still present in raw build — $patch:delete did not work")
    failed += 1

METRICS_SVC = 'ipam-capi-controller-manager-metrics-service'
if METRICS_SVC in raw_services:
    print(f"PASS: shoot metrics Service {METRICS_SVC} present — overlay delete did not over-delete")
else:
    print(f"FAIL: shoot metrics Service {METRICS_SVC} absent — over-deletion or missing metrics-service.yaml")
    failed += 1

# ── Simulate DDO rewriteWebhookURL ────────────────────────────────────────────
# urlPrefix = https://ipam-capi-remote-webhook-service:443
# For each MWC/VWC webhook clientConfig:
#   if url already set -> no-op (preserves caBundle, conversion-webhook url entries)
#   else: url = urlPrefix + service.path, delete service block
URL_PREFIX = "https://ipam-capi-remote-webhook-service:443"

sim_docs = [d for d in docs]  # shallow copy list; will mutate deeply
import copy
sim_docs = copy.deepcopy(docs)

for d in sim_docs:
    if d is None:
        continue
    if d.get('kind') in WEBHOOK_KINDS:
        for wh in d.get('webhooks', []):
            cc = wh.get('clientConfig', {})
            if 'url' in cc:
                pass  # already url-form — no-op
            elif 'service' in cc:
                svc = cc.pop('service')
                cc['url'] = URL_PREFIX + svc['path']

# ── Find webhook configs ──────────────────────────────────────────────────────
mwc = next((d for d in sim_docs if d and d.get('kind') == 'MutatingWebhookConfiguration'
            and d['metadata']['name'] == 'ipam-capi-remote-mutating-webhook-configuration'), None)
vwc = next((d for d in sim_docs if d and d.get('kind') == 'ValidatingWebhookConfiguration'
            and d['metadata']['name'] == 'ipam-capi-remote-validating-webhook-configuration'), None)

# Test: MWC present
if mwc:
    print("PASS: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration present")
else:
    print("FAIL: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration missing")
    failed += 1

# Test: VWC present
if vwc:
    print("PASS: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration present")
else:
    print("FAIL: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration missing")
    failed += 1

# Test: webhook counts (4 MWC, 4 VWC)
if mwc:
    mc = len(mwc.get('webhooks', []))
    if mc == 4:
        print("PASS: MutatingWebhookConfiguration has exactly 4 webhooks")
    else:
        print(f"FAIL: MutatingWebhookConfiguration has {mc} webhooks (expected 4)")
        failed += 1

if vwc:
    vc = len(vwc.get('webhooks', []))
    if vc == 4:
        print("PASS: ValidatingWebhookConfiguration has exactly 4 webhooks")
    else:
        print(f"FAIL: ValidatingWebhookConfiguration has {vc} webhooks (expected 4)")
        failed += 1

# Test: mutating webhook names
expected_mutating_names = [
    "default.globalinclusterippool.ipam.cluster.x-k8s.io",
    "default.globalinclusterprefixpool.ipam.cluster.x-k8s.io",
    "default.inclusterippool.ipam.cluster.x-k8s.io",
    "default.inclusterprefixpool.ipam.cluster.x-k8s.io",
]
if mwc:
    actual_names = {w['name'] for w in mwc.get('webhooks', [])}
    for name in expected_mutating_names:
        if name in actual_names:
            print(f"PASS: Mutating webhook {name} present")
        else:
            print(f"FAIL: Mutating webhook {name} missing")
            failed += 1

# Test: validating webhook names
expected_validating_names = [
    "validation.globalinclusterippool.ipam.cluster.x-k8s.io",
    "validation.globalinclusterprefixpool.ipam.cluster.x-k8s.io",
    "validation.inclusterippool.ipam.cluster.x-k8s.io",
    "validation.inclusterprefixpool.ipam.cluster.x-k8s.io",
]
if vwc:
    actual_names = {w['name'] for w in vwc.get('webhooks', [])}
    for name in expected_validating_names:
        if name in actual_names:
            print(f"PASS: Validating webhook {name} present")
        else:
            print(f"FAIL: Validating webhook {name} missing")
            failed += 1

# Test: mutating webhook URLs (after rewriteWebhookURL simulation)
expected_mutating_urls = [
    "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterippool",
    "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterprefixpool",
    "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-inclusterippool",
    "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-inclusterprefixpool",
]
if mwc:
    actual_urls = {w['clientConfig'].get('url') for w in mwc.get('webhooks', [])}
    for url in expected_mutating_urls:
        if url in actual_urls:
            print(f"PASS: Mutating webhook URL {url} present")
        else:
            print(f"FAIL: Mutating webhook URL {url} missing (got: {actual_urls})")
            failed += 1

# Test: validating webhook URLs (after rewriteWebhookURL simulation)
expected_validating_urls = [
    "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterippool",
    "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterprefixpool",
    "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-inclusterippool",
    "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-inclusterprefixpool",
]
if vwc:
    actual_urls = {w['clientConfig'].get('url') for w in vwc.get('webhooks', [])}
    for url in expected_validating_urls:
        if url in actual_urls:
            print(f"PASS: Validating webhook URL {url} present")
        else:
            print(f"FAIL: Validating webhook URL {url} missing (got: {actual_urls})")
            failed += 1

# Test: all 8 webhooks have failurePolicy: Fail
mutating_fail_count = sum(1 for w in (mwc or {}).get('webhooks', []) if w.get('failurePolicy') == 'Fail')
validating_fail_count = sum(1 for w in (vwc or {}).get('webhooks', []) if w.get('failurePolicy') == 'Fail')
if mutating_fail_count == 4 and validating_fail_count == 4:
    print("PASS: All 8 webhooks have failurePolicy: Fail")
else:
    print(f"FAIL: Not all webhooks have failurePolicy: Fail (mutating: {mutating_fail_count}/4, validating: {validating_fail_count}/4)")
    failed += 1

# Test: both configs carry injector label
LABEL = 'dual-deployment-operator.cc.sap/webhook-injector'
for obj in [mwc, vwc]:
    if obj and obj.get('metadata', {}).get('labels', {}).get(LABEL) == 'ipam-capi-remote':
        print(f"PASS: {obj['kind']} {obj['metadata']['name']} carries injector label")
    elif obj:
        print(f"FAIL: {obj['kind']} {obj['metadata']['name']} missing injector label")
        failed += 1

# Test: no service-based clientConfig remaining after simulation (all converted to url-form)
residual_svc_clients = []
for d in sim_docs:
    if d and d.get('kind') in WEBHOOK_KINDS:
        for wh in d.get('webhooks', []):
            if 'service' in wh.get('clientConfig', {}):
                residual_svc_clients.append(wh['name'])
if not residual_svc_clients:
    print("PASS: all webhook clientConfigs are url-form after simulated rewriteWebhookURL")
else:
    print(f"FAIL: service-based clientConfig still present after rewriteWebhookURL simulation: {residual_svc_clients}")
    failed += 1

print("")
if failed == 0:
    print("=== All webhook parity tests PASSED ===")
    sys.exit(0)
else:
    print(f"=== {failed} webhook parity test(s) FAILED ===")
    sys.exit(1)
PY
