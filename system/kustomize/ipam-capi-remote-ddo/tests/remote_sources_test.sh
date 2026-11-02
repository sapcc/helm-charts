#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "${1:-$(dirname "$DIR")}" <<'PY'
from pathlib import Path
import hashlib, sys, yaml
root=Path(sys.argv[1])
provider='7933583138cf1b5b16b6a1dd82a804729f83afab'
capi='5f7d58c9ad647f31bd342bf8de33092c27f7fc38'
base=f'https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/crd?ref={provider}'
shoot=yaml.safe_load((root/'shoot/kustomization.yaml').read_text())
assert shoot['resources']==['../base','../additions/shoot',base,'core-crds','rbac.yaml','webhooks.yaml','metrics-service.yaml'], 'FAIL: exact source composition missing'
assert not list((root/'shoot/crds').glob('*.yaml')), 'FAIL: copied CRDs remain'
core=yaml.safe_load((root/'shoot/core-crds/kustomization.yaml').read_text())
names=['cluster.x-k8s.io_clusters','ipam.cluster.x-k8s.io_ipaddresses','ipam.cluster.x-k8s.io_ipaddressclaims']
assert core['resources']==[f'{n}.yaml' for n in names], 'FAIL: core CRDs must be vendored'
hashes=['39768d1dbe14c7932e4fc4aacd90fcc08395f5922f74886e1a3d87868ce8d997',
        'd5068e3d0031f0cca9514492712384d4325b2481d3e6854da1192dc6d88c28cd',
        '28b61b0fc4c4a66ed2d9ca70c488eae210251662a7d2bcb5cc3ad93c46e6fa19']
assert {p.name for p in (root/'shoot/core-crds').glob('*.yaml')} == {'kustomization.yaml', *[f'{n}.yaml' for n in names]}
for name, digest in zip(names, hashes):
    assert hashlib.sha256((root/f'shoot/core-crds/{name}.yaml').read_bytes()).hexdigest()==digest, f'FAIL: vendored bytes changed: {name}'
assert len(core.get('patches',[]))==1, 'FAIL: explicit core default patch missing'
default=core['patches'][0]
assert default['target']=={'group':'apiextensions.k8s.io','version':'v1','kind':'CustomResourceDefinition'}
assert yaml.safe_load(default['patch'])==[{'op':'add','path':'/spec/conversion','value':{'strategy':'None'}}]
pools=['globalinclusterippools','globalinclusterprefixpools','inclusterippools','inclusterprefixpools']
assert shoot['patches']==[{'path':f'patches/conversion-{n}.yaml'} for n in pools]
label={'dual-deployment-operator.cc.sap/webhook-injector':'ipam-capi-remote'}
for name in pools:
    patch=yaml.safe_load((root/f'shoot/patches/conversion-{name}.yaml').read_text())
    assert set(patch)=={'apiVersion','kind','metadata','spec'}
    assert patch['apiVersion']=='apiextensions.k8s.io/v1' and patch['kind']=='CustomResourceDefinition'
    assert patch['metadata']=={'name':f'{name}.ipam.cluster.x-k8s.io', 'labels':label}
    assert set(patch['spec'])=={'conversion'}, 'FAIL: SAP patch contains copied schema'
    conversion=patch['spec']['conversion']; client=conversion['webhook']['clientConfig']
    assert conversion['strategy']=='Webhook' and conversion['webhook']['conversionReviewVersions']==['v1']
    assert client['service'] is None and client['url']=='https://ipam-capi-remote-webhook-service:443/convert'
    assert set(client)=={'service','url'}, 'FAIL: static CA or extra conversion client field'
admission=[d for d in yaml.safe_load_all((root/'shoot/webhooks.yaml').read_text()) if d]
assert {(d['kind'], d['metadata']['name']) for d in admission} == {
    ('MutatingWebhookConfiguration','ipam-capi-remote-mutating-webhook-configuration'),
    ('ValidatingWebhookConfiguration','ipam-capi-remote-validating-webhook-configuration')}
for d in admission:
    assert d['metadata']['labels']==label
    assert all('caBundle' not in w['clientConfig'] for w in d['webhooks'])
print('PASS: exact pinned Git base, byte-identical core CRDs and six dynamic-CA targets')
PY
if [[ $# -eq 0 ]]; then
python3 - "$DIR" <<'PY'
import copy, shutil, subprocess, sys, tempfile
from pathlib import Path
import yaml
directory=Path(sys.argv[1]); root=directory.parent
shoot=yaml.safe_load((root/'shoot/kustomization.yaml').read_text())
core=yaml.safe_load((root/'shoot/core-crds/kustomization.yaml').read_text())
patch_path='shoot/patches/conversion-globalinclusterippools.yaml'
patch=yaml.safe_load((root/patch_path).read_text())
cases=[]
bad=copy.deepcopy(shoot); bad['resources'][2]=bad['resources'][2].split('?')[0]+'?ref=v1.1.1'
cases.append(('mutable provider tag','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad['resources'][0]='https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/v1.14.2/core/config/crd/bases/cluster.x-k8s.io_clusters.yaml'
cases.append(('raw HTTP CAPI resource','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad['resources']=['https://github.com/kubernetes-sigs/cluster-api//core/config/crd?ref=5f7d58c9ad647f31bd342bf8de33092c27f7fc38']
cases.append(('full CAPI directory','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(patch); bad['spec']['conversion']['webhook']['clientConfig']['service']={'name':'webhook-service'}
cases.append(('service and URL coexist','shoot/patches/conversion-globalinclusterippools.yaml',bad))
bad=copy.deepcopy(shoot); bad['patches'].pop()
cases.append(('missing pool patch','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad.pop('patches')
cases.append(('missing explicit core default','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(patch); bad['spec']['conversion']['webhook']['clientConfig']['caBundle']='captured'
cases.append(('static pool CA',patch_path,bad))
bad=copy.deepcopy(patch); bad['metadata']['labels']={}
cases.append(('missing pool target label',patch_path,bad))
vendor_path='shoot/core-crds/cluster.x-k8s.io_clusters.yaml'
bad=yaml.safe_load((root/vendor_path).read_text()); bad['spec']['group']='mutated.example'
cases.append(('vendored schema bytes',vendor_path,bad))
for name,path,document in cases:
    with tempfile.TemporaryDirectory() as tmp:
        target=Path(tmp)/'overlay'; shutil.copytree(root,target)
        (target/path).write_text(yaml.safe_dump(document))
        result=subprocess.run(['bash',str(directory/'remote_sources_test.sh'),str(target)],capture_output=True,text=True)
        assert result.returncode!=0, f'FAIL: accepted {name}'
        print(f'PASS: rejects {name}')
PY
fi
