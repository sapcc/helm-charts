#!/usr/bin/env bash
# Consolidated contract/parity driver.  Three sections:
#   (2a) semantic 7-CRD surface check — exact names, split controller-gen stamps,
#        pool move-hierarchy labels, and injector label.
#   (2b) crd_parity.py self-test — 10 synthetic cases exercising the fingerprint
#        lib's fail-closed edge cases directly.
#   (2c) real-render baseline parity — compares the ACTUAL seed/shoot renders to
#        the reviewed committed baseline (crd-baseline.json), closing the blind spot
#        where (2b) only exercised a synthetic CRD and never checked real output.
#   (3) explicit 8-webhook URL contract — human-readable assertion of the exact
#       mutate/validate URLs after a simulated DDO rewriteWebhookURL, plus a
#       Service inventory guard (upstream webhook-service deleted by $patch:delete).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$DIR")"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ipam-contract.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

kustomize build "$ROOT/shoot" > "$WORK/shoot.yaml"
kustomize build "$ROOT/seed"  > "$WORK/seed.yaml"

# ── (2a) semantic 7-CRD surface check ────────────────────────────────────────
# Exact 7 CRDs by name, split controller-gen stamps (pool v0.17.2 / core v0.21.0),
# pool move-hierarchy labels, and injector label.  Build-time render is service-form
# (DDO rewriteWebhookURL converts to url-form at deploy time); no url/service
# assertions at build time — that is expected and correct for Design B.
PYTHONDONTWRITEBYTECODE=1 python3 - "$WORK/shoot.yaml" <<'PY'
import sys, yaml
docs = [d for d in yaml.safe_load_all(open(sys.argv[1])) if d and d['kind']=='CustomResourceDefinition']
pools = {'globalinclusterippools', 'globalinclusterprefixpools', 'inclusterippools', 'inclusterprefixpools'}
names = {f'{n}.ipam.cluster.x-k8s.io' for n in pools | {'ipaddresses', 'ipaddressclaims'}} | {'clusters.cluster.x-k8s.io'}
assert len(docs)==7 and {d['metadata']['name'] for d in docs}==names
for d in docs:
    meta=d['metadata']; pool=meta['name'].split('.')[0] in pools
    assert meta.get('annotations',{}).get('controller-gen.kubebuilder.io/version') == ('v0.17.2' if pool else 'v0.21.0')
    labels=meta.get('labels',{})
    if pool:
        assert labels.get('clusterctl.cluster.x-k8s.io/move-hierarchy') == ''
        assert labels['dual-deployment-operator.cc.sap/webhook-injector']=='ipam-capi-remote'
    else:
        assert 'clusterctl.cluster.x-k8s.io/move-hierarchy' not in labels
print('PASS: exact seven CRDs, split stamps, move-hierarchy labels, injector label (service-form conversion inherited from upstream)')
PY

# ── (2b) crd_parity.py self-test (10 synthetic cases) ────────────────────────
python3 - "$DIR" <<'PY'
import copy, importlib.util, json, subprocess, sys, tempfile
from pathlib import Path
import yaml
directory = Path(sys.argv[1])
sys.dont_write_bytecode = True
utility = directory / 'crd_parity.py'
assert utility.is_file(), 'FAIL: mandatory parity utility is absent'
spec = importlib.util.spec_from_file_location('parity', utility)
parity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parity)
original = {'apiVersion': 'apiextensions.k8s.io/v1', 'kind': 'CustomResourceDefinition',
            'metadata': {'name': 'example.test'},
            'spec': {'versions': [{'name': 'v1', 'served': True, 'storage': True}],
                     'conversion': {'webhook': {'clientConfig': {'caBundle': 'original'}}}}}
with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    shoot, seed, baseline = (tmp / name for name in ('shoot.yaml', 'seed.yaml', 'baseline.json'))
    seed.write_text('')
    baseline.write_text(json.dumps({'seed': {}, 'shoot': parity.fingerprints([original])}))
    def check(name, docs, expected, baseline_path=baseline):
        shoot.write_text(yaml.safe_dump_all(docs))
        result = subprocess.run([sys.executable, str(utility), str(shoot), str(seed), str(baseline_path)], capture_output=True, text=True)
        assert (result.returncode == 0) == expected, f'{name}: {result.stdout} {result.stderr}'
        print(f'PASS: {name}')
    check('unchanged manifest', [original], True)
    check('missing CRD', [], False)
    added = copy.deepcopy(original); added['metadata']['name'] = 'extra.test'
    check('extra CRD', [original, added], False)
    check('duplicate identity', [original, original], False)
    changed = copy.deepcopy(original); changed['spec']['versions'][0]['served'] = False
    check('schema/version changed', [changed], False)
    changed = copy.deepcopy(original); changed['spec']['conversion']['webhook']['clientConfig']['caBundle'] = 'different'
    check('CA changed', [changed], False)
    check('missing baseline fails closed', [original], False, tmp / 'absent.json')
    changed = copy.deepcopy(original); changed['metadata']['uid'] = 'server-assigned'
    check('server metadata normalized', [changed], True)
    changed = copy.deepcopy(original); changed['metadata']['labels'] = {'meaningful': 'changed'}
    check('meaningful metadata preserved', [changed], False)
    tampered=json.loads(baseline.read_text())
    tampered['shoot'][next(iter(tampered['shoot']))]='0'*64
    baseline.write_text(json.dumps(tampered))
    check('changed baseline fingerprint rejected', [original], False)
PY

# ── (2c) Real-render baseline parity ─────────────────────────────────────────
# Compare the ACTUAL seed/shoot renders to the reviewed committed baseline
# (crd-baseline.json). This closes the blind spot where the self-test (2b) only
# exercised a synthetic CRD and never checked real output.
echo "=== (2c) Real-render baseline parity ==="
python3 "$DIR/crd_parity.py" "$WORK/shoot.yaml" "$WORK/seed.yaml" "$DIR/crd-baseline.json"

# ── (3) explicit 8-webhook URL contract (simulated DDO rewriteWebhookURL) ─────
# Legible string-level assertion of the exact mutate/validate URLs, plus the raw-build
# Service inventory guard (webhook-service deleted by overlay $patch:delete).
# Structural equality is already enforced by crd_parity; this section exists so a
# URL regression produces a human-readable failure.
PYTHONDONTWRITEBYTECODE=1 python3 - "$WORK/shoot.yaml" <<'PY'
import copy, sys, yaml

with open(sys.argv[1]) as f:
    docs = list(yaml.safe_load_all(f))

WEBHOOK_KINDS = {'MutatingWebhookConfiguration', 'ValidatingWebhookConfiguration'}
failed = 0

# Service inventory on the RAW build (before any simulation).
raw_services = {d['metadata']['name']: d for d in docs if d and d.get('kind') == 'Service'}
if 'webhook-service' not in raw_services:
    print("PASS: upstream webhook-service (Service) absent from raw build — overlay deleted it")
else:
    print("FAIL: webhook-service (Service) still present in raw build — $patch:delete did not work")
    failed += 1
METRICS_SVC = 'ipam-capi-controller-manager-metrics-service'
if METRICS_SVC not in raw_services:
    print(f"PASS: controller metrics Service {METRICS_SVC} absent — dead object removed from overlay")
else:
    print(f"FAIL: controller metrics Service {METRICS_SVC} still present — deletion did not take effect")
    failed += 1

# Simulate DDO rewriteWebhookURL: service-form clientConfig -> url = urlPrefix + service.path.
URL_PREFIX = "https://ipam-capi-remote-webhook-service:443"
sim_docs = copy.deepcopy(docs)
for d in sim_docs:
    if d and d.get('kind') in WEBHOOK_KINDS:
        for wh in d.get('webhooks', []):
            cc = wh.get('clientConfig', {})
            if 'url' in cc:
                pass  # already url-form — no-op
            elif 'service' in cc:
                svc = cc.pop('service')
                cc['url'] = URL_PREFIX + svc['path']

mwc = next((d for d in sim_docs if d and d.get('kind') == 'MutatingWebhookConfiguration'
            and d['metadata']['name'] == 'ipam-capi-remote-mutating-webhook-configuration'), None)
vwc = next((d for d in sim_docs if d and d.get('kind') == 'ValidatingWebhookConfiguration'
            and d['metadata']['name'] == 'ipam-capi-remote-validating-webhook-configuration'), None)

if mwc:
    print("PASS: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration present")
else:
    print("FAIL: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration missing")
    failed += 1
if vwc:
    print("PASS: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration present")
else:
    print("FAIL: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration missing")
    failed += 1

if mwc:
    mc = len(mwc.get('webhooks', []))
    print("PASS: MutatingWebhookConfiguration has exactly 4 webhooks" if mc == 4
          else f"FAIL: MutatingWebhookConfiguration has {mc} webhooks (expected 4)")
    failed += mc != 4
if vwc:
    vc = len(vwc.get('webhooks', []))
    print("PASS: ValidatingWebhookConfiguration has exactly 4 webhooks" if vc == 4
          else f"FAIL: ValidatingWebhookConfiguration has {vc} webhooks (expected 4)")
    failed += vc != 4

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
            print(f"FAIL: Mutating webhook {name} missing"); failed += 1

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
            print(f"FAIL: Validating webhook {name} missing"); failed += 1

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
            print(f"FAIL: Mutating webhook URL {url} missing (got: {actual_urls})"); failed += 1

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
            print(f"FAIL: Validating webhook URL {url} missing (got: {actual_urls})"); failed += 1

mutating_fail_count = sum(1 for w in (mwc or {}).get('webhooks', []) if w.get('failurePolicy') == 'Fail')
validating_fail_count = sum(1 for w in (vwc or {}).get('webhooks', []) if w.get('failurePolicy') == 'Fail')
if mutating_fail_count == 4 and validating_fail_count == 4:
    print("PASS: All 8 webhooks have failurePolicy: Fail")
else:
    print(f"FAIL: Not all webhooks have failurePolicy: Fail (mutating: {mutating_fail_count}/4, validating: {validating_fail_count}/4)")
    failed += 1

LABEL = 'dual-deployment-operator.cc.sap/webhook-injector'
for obj in [mwc, vwc]:
    if obj and obj.get('metadata', {}).get('labels', {}).get(LABEL) == 'ipam-capi-remote':
        print(f"PASS: {obj['kind']} {obj['metadata']['name']} carries injector label")
    elif obj:
        print(f"FAIL: {obj['kind']} {obj['metadata']['name']} missing injector label"); failed += 1

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
    print("=== All webhook URL contract assertions PASSED ===")
    sys.exit(0)
else:
    print(f"=== {failed} webhook URL contract assertion(s) FAILED ===")
    sys.exit(1)
PY
