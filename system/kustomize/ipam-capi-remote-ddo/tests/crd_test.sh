#!/usr/bin/env bash
# Consolidated CRD test:
#   (a) semantic 7-CRD check (from crd_diff_test.sh)
#   (b) production crd_parity.py baseline gate: nothing ran it directly;
#       migration_contract.py owns the real-baseline parity internally —
#       crd_diff_test.sh's migration_contract.py call is omitted here because
#       migration_contract_test.sh is the sole owner of that gate.
#   (c) crd_parity.py self-test (9 synthetic cases from crd_parity_test.sh)
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$DIR")"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ipam-crd-parity.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ── (a) Build shoot+seed; run semantic 7-CRD check ───────────────────────────
kustomize build "$ROOT/shoot" > "$WORK/shoot.yaml"
kustomize build "$ROOT/seed"  > "$WORK/seed.yaml"
python3 - "$WORK/shoot.yaml" <<'PY'
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
        conversion=d['spec']['conversion']; client=conversion['webhook']['clientConfig']
        assert conversion['strategy']=='Webhook' and conversion['webhook']['conversionReviewVersions']==['v1']
        assert client['url']=='https://ipam-capi-remote-webhook-service:443/convert'
        assert 'caBundle' not in client and 'service' not in client
        assert labels['dual-deployment-operator.cc.sap/webhook-injector']=='ipam-capi-remote'
    else:
        assert 'clusterctl.cluster.x-k8s.io/move-hierarchy' not in labels
print('PASS: exact seven CRDs, split stamps, labels and URL-only conversion')
PY

# ── (c) crd_parity.py self-test (9 synthetic cases) ──────────────────────────
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
