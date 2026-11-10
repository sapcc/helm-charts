#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 - "${1:-$(dirname "$DIR")}" <<'PY'
from pathlib import Path
import hashlib, sys, yaml
root=Path(sys.argv[1])
provider='7933583138cf1b5b16b6a1dd82a804729f83afab'
capi='5f7d58c9ad647f31bd342bf8de33092c27f7fc38'
crd_base=f'github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/crd?ref={provider}'
webhook_base=f'github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/webhook?ref={provider}'
shoot=yaml.safe_load((root/'shoot/kustomization.yaml').read_text())
# Exact resource composition: both CRD and webhook remotes must be scheme-less SHA-pinned git refs.
assert shoot['resources']==['../additions/shoot',crd_base,'core-crds','rbac.yaml',webhook_base,'metrics-service.yaml'], 'FAIL: exact source composition missing'
# webhooks.yaml must NOT be a local file resource (it is now sourced remotely)
assert 'webhooks.yaml' not in shoot['resources'], 'FAIL: hand-authored webhooks.yaml still listed as local resource'
assert not list((root/'shoot/crds').glob('*.yaml')), 'FAIL: copied CRDs remain'
core=yaml.safe_load((root/'shoot/core-crds/kustomization.yaml').read_text())
names=['cluster.x-k8s.io_clusters','ipam.cluster.x-k8s.io_ipaddresses','ipam.cluster.x-k8s.io_ipaddressclaims']
import re
expected_core=[f'https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/{capi}/core/config/crd/bases/{n}.yaml' for n in names]
assert core['resources']==expected_core, 'FAIL: core CRDs must be SHA-pinned raw file URLs'
for url in core['resources']:
    ref=re.match(r'https://raw\.githubusercontent\.com/kubernetes-sigs/cluster-api/([0-9a-f]+)/core/config/crd/bases/', url)
    assert ref and len(ref.group(1))==40, f'FAIL: core ref must be a full 40-hex commit (immutable): {url}'
    assert ref.group(1)==capi, f'FAIL: core ref must be the pinned commit: {url}'
assert {p.name for p in (root/'shoot/core-crds').glob('*.yaml')} == {'kustomization.yaml'}, 'FAIL: no CRD bytes may be vendored under core-crds'
assert len(core.get('patches',[]))==1, 'FAIL: explicit core default patch missing'
default=core['patches'][0]
assert default['target']=={'group':'apiextensions.k8s.io','version':'v1','kind':'CustomResourceDefinition'}
assert yaml.safe_load(default['patch'])==[{'op':'add','path':'/spec/conversion','value':{'strategy':'None'}}]
pools=['globalinclusterippools','globalinclusterprefixpools','inclusterippools','inclusterprefixpools']
label={'dual-deployment-operator.cc.sap/webhook-injector':'ipam-capi-remote'}
# shoot patches: 1 pool-CRD regex label patch + 1 Service delete patch + 2 webhook rename+label patches
assert len(shoot.get('patches',[]))==4, f'FAIL: expected 4 patches (1 pool CRD regex label + 1 svc-delete + 2 webhook rename), got {len(shoot.get("patches",[]))}'
# Index 0: single regex-targeted patch that labels all four pool CRDs
pool_patch=shoot['patches'][0]
assert pool_patch.get('target')=={'kind':'CustomResourceDefinition','name':'^(global)?incluster(ip|prefix)pools\\.ipam\\.cluster\\.x-k8s\\.io$'}, f'FAIL: pool CRD regex label patch target missing or wrong: {pool_patch.get("target")}'
pool_ops=yaml.safe_load(pool_patch['patch'])
assert len(pool_ops)==1 and pool_ops[0]=={'op':'add','path':'/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector','value':'ipam-capi-remote'}, f'FAIL: pool CRD regex label patch must add the injector label via JSON Pointer-escaped op: {pool_ops}'
# Index 1: upstream webhook-service (Service) targeted delete patch
svc_del=shoot['patches'][1]
assert svc_del.get('target')=={'kind':'Service','name':'webhook-service'}, 'FAIL: webhook-service delete patch target missing'
assert '$patch: delete' in svc_del.get('patch',''), 'FAIL: webhook-service delete patch must use $patch: delete'
# Indices 2-3: inline webhook rename+label patches
mwc_patch=shoot['patches'][2]
assert mwc_patch.get('target')=={'kind':'MutatingWebhookConfiguration','name':'mutating-webhook-configuration'}, 'FAIL: MWC rename patch target missing'
assert yaml.safe_load(mwc_patch['patch'])[0]=={'op':'replace','path':'/metadata/name','value':'ipam-capi-remote-mutating-webhook-configuration'}, 'FAIL: MWC rename op missing'
vwc_patch=shoot['patches'][3]
assert vwc_patch.get('target')=={'kind':'ValidatingWebhookConfiguration','name':'validating-webhook-configuration'}, 'FAIL: VWC rename patch target missing'
assert yaml.safe_load(vwc_patch['patch'])[0]=={'op':'replace','path':'/metadata/name','value':'ipam-capi-remote-validating-webhook-configuration'}, 'FAIL: VWC rename op missing'
# Confirm no per-pool file patches remain (collapsed into inline regex patch above)
assert not list((root/'shoot/patches').glob('conversion-*.yaml')), 'FAIL: per-pool conversion-*.yaml file patches still present (should be collapsed into inline regex patch)'
# Confirm webhooks.yaml does not exist as a local file (sourced remotely now)
assert not (root/'shoot/webhooks.yaml').exists(), 'FAIL: shoot/webhooks.yaml still exists as local file (should be remote-sourced)'
print('PASS: exact pinned Git base, SHA-pinned raw core CRD URLs, six dynamic-CA targets, webhook remote-sourcing, svc-delete patch')
PY
if [[ $# -eq 0 ]]; then
python3 - "$DIR" <<'PY'
import copy, shutil, subprocess, sys, tempfile
from pathlib import Path
import yaml
directory=Path(sys.argv[1]); root=directory.parent
shoot=yaml.safe_load((root/'shoot/kustomization.yaml').read_text())
core=yaml.safe_load((root/'shoot/core-crds/kustomization.yaml').read_text())
cases=[]
bad=copy.deepcopy(shoot); bad['resources'][1]=bad['resources'][1].split('?')[0]+'?ref=v1.1.1'
cases.append(('mutable provider CRD tag','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(shoot); bad['resources'][4]=bad['resources'][4].split('?')[0]+'?ref=v1.1.1'
cases.append(('mutable provider webhook tag','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad['resources'][0]='https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/v1.14.2/core/config/crd/bases/cluster.x-k8s.io_clusters.yaml'
cases.append(('mutable core tag','shoot/core-crds/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad['resources']=['https://github.com/kubernetes-sigs/cluster-api//core/config/crd?ref=5f7d58c9ad647f31bd342bf8de33092c27f7fc38']
cases.append(('full CAPI directory','shoot/core-crds/kustomization.yaml',bad))
# Drop only the two webhook-rename patches (indices 2-3); keep pool-label (0) + svc-delete (1)
bad=copy.deepcopy(shoot); bad['patches']=bad['patches'][:2]
cases.append(('missing webhook rename patches','shoot/kustomization.yaml',bad))
# Drop the pool-CRD regex label patch (index 0)
bad=copy.deepcopy(shoot); bad['patches']=bad['patches'][1:]
cases.append(('missing pool patch','shoot/kustomization.yaml',bad))
# Drop the svc-delete patch (index 1)
bad=copy.deepcopy(shoot); bad['patches']=bad['patches'][:1]+bad['patches'][2:]
cases.append(('missing svc-delete patch','shoot/kustomization.yaml',bad))
bad=copy.deepcopy(core); bad.pop('patches')
cases.append(('missing explicit core default','shoot/core-crds/kustomization.yaml',bad))
# Pool-CRD regex patch with wrong (empty) label value — injector label would be absent
bad=copy.deepcopy(shoot); bad['patches'][0]['patch']=yaml.dump([{'op':'add','path':'/metadata/labels/dual-deployment-operator.cc.sap~1webhook-injector','value':''}])
cases.append(('missing pool target label','shoot/kustomization.yaml',bad))
# Pool-CRD regex patch with too-narrow target (misses the global* variants)
bad=copy.deepcopy(shoot); bad['patches'][0]['target']['name']='^incluster(ip|prefix)pools\\.ipam\\.cluster\\.x-k8s\\.io$'
cases.append(('pool regex misses global variants','shoot/kustomization.yaml',bad))
for name,path,document in cases:
    with tempfile.TemporaryDirectory() as tmp:
        target=Path(tmp)/'overlay'; shutil.copytree(root,target)
        (target/path).write_text(yaml.safe_dump(document))
        result=subprocess.run(['bash',str(directory/'remote_sources_test.sh'),str(target)],capture_output=True,text=True)
        assert result.returncode!=0, f'FAIL: accepted {name}'
        print(f'PASS: rejects {name}')
PY
fi
