#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$(dirname "$DIR")" <<'PY'
from pathlib import Path
import sys, yaml
root=Path(sys.argv[1])
provider='7933583138cf1b5b16b6a1dd82a804729f83afab'
capi='5f7d58c9ad647f31bd342bf8de33092c27f7fc38'
base=f'https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/crd?ref={provider}'
shoot=yaml.safe_load((root/'shoot/kustomization.yaml').read_text())
assert shoot['resources']==['../base','../additions/shoot',base,'core-crds','rbac.yaml','webhooks.yaml'], 'FAIL: exact remote source composition missing'
assert not list((root/'shoot/crds').glob('*.yaml')), 'FAIL: copied CRDs remain'
core=yaml.safe_load((root/'shoot/core-crds/kustomization.yaml').read_text())
names=['cluster.x-k8s.io_clusters','ipam.cluster.x-k8s.io_ipaddresses','ipam.cluster.x-k8s.io_ipaddressclaims']
assert core['resources']==[f'https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/{capi}/core/config/crd/bases/{n}.yaml' for n in names]
pools=['globalinclusterippools','globalinclusterprefixpools','inclusterippools','inclusterprefixpools']
assert shoot['patches']==[{'path':f'patches/conversion-{n}.yaml'} for n in pools]
cas=[]
for name in pools:
    patch=yaml.safe_load((root/f'shoot/patches/conversion-{name}.yaml').read_text())
    assert set(patch)=={'apiVersion','kind','metadata','spec'}
    assert patch['apiVersion']=='apiextensions.k8s.io/v1' and patch['kind']=='CustomResourceDefinition'
    assert patch['metadata']=={'name':f'{name}.ipam.cluster.x-k8s.io'}
    assert set(patch['spec'])=={'conversion'}, 'FAIL: SAP patch contains copied schema'
    conversion=patch['spec']['conversion']; client=conversion['webhook']['clientConfig']
    assert conversion['strategy']=='Webhook' and conversion['webhook']['conversionReviewVersions']==['v1']
    assert client['service'] is None and client['url']=='https://ipam-capi-remote-webhook-service:443/convert'
    assert client['caBundle']; cas.append(client['caBundle'])
assert len(set(cas))==1
print('PASS: exact SHA-pinned Git/HTTP sources and four SAP-only conversion patches')
PY
