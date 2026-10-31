#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "${1:-$(dirname "$DIR")}" <<'PY'
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
assert len(core.get('patches',[]))==1, 'FAIL: explicit core default patch missing'
default=core['patches'][0]
assert default['target']=={'group':'apiextensions.k8s.io','version':'v1','kind':'CustomResourceDefinition'}
assert yaml.safe_load(default['patch'])==[{'op':'add','path':'/spec/conversion','value':{'strategy':'None'}}]
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
bad=copy.deepcopy(core); bad['resources']=[u.replace('5f7d58c9ad647f31bd342bf8de33092c27f7fc38','v1.14.2') for u in bad['resources']]
cases.append(('mutable CAPI tag','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad['resources']=['https://github.com/kubernetes-sigs/cluster-api//core/config/crd?ref=5f7d58c9ad647f31bd342bf8de33092c27f7fc38']
cases.append(('full CAPI directory','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(patch); bad['spec']['conversion']['webhook']['clientConfig']['service']={'name':'webhook-service'}
cases.append(('service and URL coexist','shoot/patches/conversion-globalinclusterippools.yaml',bad))
bad=copy.deepcopy(shoot); bad['patches'].pop()
cases.append(('missing pool patch','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad.pop('patches')
cases.append(('missing explicit core default','shoot/core-crds/kustomization.yaml',bad))
for name,path,document in cases:
    with tempfile.TemporaryDirectory() as tmp:
        target=Path(tmp)/'overlay'; shutil.copytree(root,target)
        (target/path).write_text(yaml.safe_dump(document))
        result=subprocess.run(['bash',str(directory/'remote_sources_test.sh'),str(target)],capture_output=True,text=True)
        assert result.returncode!=0, f'FAIL: accepted {name}'
        print(f'PASS: rejects {name}')
PY
fi
