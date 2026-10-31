#!/usr/bin/env bash
# Always compare against tracked fingerprints; no optional-capture dependency.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$DIR")"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ipam-crd-parity.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
kustomize build "$ROOT/shoot" > "$WORK/shoot.yaml"
kustomize build "$ROOT/seed" > "$WORK/seed.yaml"
PYTHONDONTWRITEBYTECODE=1 python3 "$DIR/migration_contract.py" "$WORK/shoot.yaml" "$WORK/seed.yaml"
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
