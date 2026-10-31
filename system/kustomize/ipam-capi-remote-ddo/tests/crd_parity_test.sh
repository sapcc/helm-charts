#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$DIR" <<'PY'
import copy, importlib.util, json, subprocess, sys, tempfile
from pathlib import Path
import yaml
directory = Path(sys.argv[1])
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
