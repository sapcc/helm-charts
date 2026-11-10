"""Independent, pinned Helm oracle. No live captures or candidate-derived values."""
import base64
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile

import yaml

LEGACY = '97d52c25ae067c00fd5f5b3e7a66771fdcbc10db'
HISTORICAL = 'c4b1964d0e4fc4e03687ab735cb485ab7b9808ef'
ROOT = Path(__file__).resolve().parent.parent
REPO = ROOT.parents[2]
PREFIX = 'system/kustomize/ipam-capi-remote-ddo/'
CLUSTER_KINDS = {'CustomResourceDefinition', 'ClusterRole', 'ClusterRoleBinding',
                 'MutatingWebhookConfiguration', 'ValidatingWebhookConfiguration'}


def git_file(commit, path):
    return subprocess.check_output(['git', 'show', f'{commit}:{path}'], cwd=REPO)


def documents(text):
    return [d for d in yaml.safe_load_all(text) if d]


def place(docs, namespace):
    for doc in docs:
        if doc['kind'] not in CLUSTER_KINDS:
            doc['metadata'].setdefault('namespace', namespace)
    return docs


def render(namespace):
    with tempfile.TemporaryDirectory(prefix='ipam-migration-') as work:
        archive = subprocess.check_output(
            ['git', 'archive', LEGACY, 'system/ipam-capi-remote'], cwd=REPO)
        with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
            bundle.extractall(work, filter='data')
        values = {
            'controllerManager': {'manager': {
                'image': {'repository': 'keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller', 'tag': 'v1.1.1'},
                'podSecurityContext': {'runAsNonRoot': True, 'runAsUser': 65532,
                    'runAsGroup': 65532, 'seccompProfile': {'type': 'RuntimeDefault'},
                    'allowPrivilegeEscalation': False, 'capabilities': {'drop': ['ALL']}}}},
            'webhookInjector': {
                'repository': 'keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector',
                'tag': 'sha-bb2f978ca889e1da27c33faba3fe78b1b1dfd221'},
        }
        values_path = Path(work) / 'values.yaml'
        values_path.write_text(yaml.safe_dump(values))
        rendered = subprocess.check_output(['helm', 'template', 'ipam-capi-remote',
            str(Path(work) / 'system/ipam-capi-remote'), '--namespace', namespace,
            '--api-versions', 'monitoring.coreos.com/v1', '-f', str(values_path)])
    all_docs = documents(rendered)
    wrappers = [d for d in all_docs if d['kind'] == 'ManagedResource']
    payload_names = {r['name'] for d in wrappers for r in d['spec']['secretRefs']}
    shoot, seed = [], []
    for doc in all_docs:
        kind, name = doc['kind'], doc['metadata']['name']
        if kind == 'ManagedResource':
            continue
        if kind == 'Secret' and name in payload_names:
            shoot.extend(documents(base64.b64decode(doc['data']['objects.yaml'])))
        elif kind == 'ConfigMap' and name == 'ipam-capi-remote-webhook-config':
            shoot.extend(documents(doc['data']['webhooks.yaml']))
        else:
            seed.append(doc)
    return {'seed': place(seed, namespace), 'shoot': place(shoot, 'kube-system')}
