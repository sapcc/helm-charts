"""Fail-closed, per-identity migration checks against the actual pinned chart."""
import copy
import hashlib
import json
from pathlib import Path
import sys

import yaml

from crd_parity import fingerprints
from migration_render import ROOT, PREFIX, HISTORICAL, documents, git_file, place, render

LABEL = 'dual-deployment-operator.cc.sap/webhook-injector'
ORIGIN = 'dual-deployment-operator.cc.sap/origin'
INJECTOR = 'ipam-capi-remote-webhook-injector'
POOLS = [n + '.ipam.cluster.x-k8s.io' for n in (
    'globalinclusterippools', 'globalinclusterprefixpools',
    'inclusterippools', 'inclusterprefixpools')]
CORE = ['clusters.cluster.x-k8s.io', 'ipaddresses.ipam.cluster.x-k8s.io',
        'ipaddressclaims.ipam.cluster.x-k8s.io']
ADMISSION = {'MutatingWebhookConfiguration': 'ipam-capi-remote-mutating-webhook-configuration',
             'ValidatingWebhookConfiguration': 'ipam-capi-remote-validating-webhook-configuration'}
URL = 'https://ipam-capi-remote-webhook-service:443/convert'
URL_PREFIX = 'https://ipam-capi-remote-webhook-service:443'
# Build-time service-form (Design B: DDO rewriteWebhookURL converts to url-form at deploy).
NEW_CONVERSION = {'strategy': 'Webhook', 'webhook': {
    'clientConfig': {'service': {'name': 'webhook-service', 'namespace': 'system', 'path': '/convert'}},
    'conversionReviewVersions': ['v1']}}
OLD_CONVERSION = {'strategy': 'Webhook', 'webhook': {
    'clientConfig': {'service': {'name': 'webhook-service', 'namespace': 'kube-system', 'path': '/convert'}},
    'conversionReviewVersions': ['v1']}}
NEW_RULES = [
    {'apiGroups': ['apiextensions.k8s.io'], 'resources': ['customresourcedefinitions'],
     'resourceNames': POOLS, 'verbs': ['get', 'patch']},
    {'apiGroups': ['apiextensions.k8s.io'], 'resources': ['customresourcedefinitions'],
     'verbs': ['list', 'watch']},
    {'apiGroups': ['admissionregistration.k8s.io'], 'resources': ['mutatingwebhookconfigurations'],
     'resourceNames': [ADMISSION['MutatingWebhookConfiguration']], 'verbs': ['get', 'patch']},
    {'apiGroups': ['admissionregistration.k8s.io'], 'resources': ['validatingwebhookconfigurations'],
     'resourceNames': [ADMISSION['ValidatingWebhookConfiguration']], 'verbs': ['get', 'patch']},
    {'apiGroups': ['admissionregistration.k8s.io'],
     'resources': ['mutatingwebhookconfigurations', 'validatingwebhookconfigurations'],
     'verbs': ['list', 'watch']},
]
OLD_RULES = [
    {'apiGroups': ['admissionregistration.k8s.io'],
     'resources': ['mutatingwebhookconfigurations', 'validatingwebhookconfigurations'],
     'verbs': ['get', 'list', 'watch', 'create', 'update', 'patch']},
    {'apiGroups': ['apiextensions.k8s.io'], 'resources': ['customresourcedefinitions'],
     'verbs': ['get', 'list', 'watch']},
]
NEW_ARGS = [
    '--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig',
    f'--target-label={LABEL}=ipam-capi-remote',
    '--leader-election-id=ipam-capi-remote-webhook-injector-leader',
    '--cert-secret-name=ipam-capi-remote-cert-secret',
    '--cert-sans=ipam-capi-remote-webhook-service',
    '--rotation-overlap-window=30s', '--rotation-gate-timeout=30s',
]
OLD_ARGS = ['--webhook-config-name=ipam-capi-remote-webhook-config',
    NEW_ARGS[0], *NEW_ARGS[2:5],
    '--managed-resource-label=ipam-capi-remote-webhook-injector=true',
    '--external-host=ipam-capi-remote-webhook-service', '--external-port=443', *NEW_ARGS[5:]]
RESTORED = {
    'seed': {('NetworkPolicy', 'ipam-capi-ingress-from-kube-apiserver'),
             ('NetworkPolicy', 'kube-apiserver-egress-to-ipam-capi'),
             ('NetworkPolicy', 'ipam-capi-ingress-from-kube-monitoring'),
             ('ConfigMap', 'ipam-capi-manager-config')},
    'shoot': {('Service', 'ipam-capi-controller-manager-metrics-service')},
}
# Oracle-inventory objects the reorg intentionally dropped from the overlay.
# The pinned Helm chart still emits them, so they are filtered out of the
# expected set rather than asserted present. Justification: the webhook-injector
# seed ClusterRole/ClusterRoleBinding were an unused managed-resource-mode
# leftover; the two shoot leader-election pairs were a GRM namespace-limit
# workaround and the manager runs --leader-elect=false.
DROPPED = {
    'seed': {('ClusterRole', INJECTOR), ('ClusterRoleBinding', INJECTOR)},
    'shoot': {('ClusterRole', 'ipam-capi-leader-election-role'),
              ('ClusterRoleBinding', 'ipam-capi-leader-election-rolebinding'),
              ('ClusterRole', 'ipam-capi-remote-leader-election-role'),
              ('ClusterRoleBinding', 'ipam-capi-remote-leader-election-rolebinding')},
}
# Objects new in the overlay that have no counterpart in the legacy Helm render.
# They appear in `kustomize build shoot/` but are not compared in parity tests.
# NOTE: after the fix that deletes webhook-service via $patch:delete in the overlay,
# there are NO such objects — the upstream webhook-service (Service) is removed before
# it reaches DDO or the render output.  This dict is kept as a named constant so the
# filtering logic below remains explicit; both sets are empty.
ADDED = {
    'seed': set(),
    'shoot': set(),
}


def index(docs):
    result = {}
    for doc in docs:
        key = (doc['apiVersion'], doc['kind'], doc['metadata'].get('namespace', ''), doc['metadata']['name'])
        assert key not in result, f'duplicate identity: {key}'
        result[key] = doc
    return result


def get(docs, kind, name):
    matches = [d for d in docs if (d['kind'], d['metadata']['name']) == (kind, name)]
    assert len(matches) == 1, f'expected one {kind}/{name}'
    return matches[0]


def prune_empty_metadata(doc):
    for field in ('labels', 'annotations'):
        if doc['metadata'].get(field) == {}:
            del doc['metadata'][field]


def remove_target(new, old):
    assert old['metadata'].get('labels', {}).get(LABEL) is None
    assert new['metadata']['labels'].pop(LABEL) == 'ipam-capi-remote'


def delivered(raw, namespace):
    result = copy.deepcopy(raw)
    place(result['seed'], namespace)
    place(result['shoot'], 'kube-system')
    return result


def compare(raw, legacy, namespace):
    candidate = delivered(raw, namespace)
    target_names = set(POOLS) | set(ADMISSION.values())
    actual_targets = {d['metadata']['name'] for mode in candidate.values() for d in mode
                      if LABEL in d['metadata'].get('labels', {})}
    assert actual_targets == target_names, 'exactly six injector targets required'
    for mode, count in (('seed', 13), ('shoot', 21)):
        actual = index(d for d in candidate[mode]
                       if (d['kind'], d['metadata']['name']) not in ADDED[mode])
        expected = index(d for d in legacy[mode]
                         if (d['kind'], d['metadata']['name']) not in DROPPED[mode])
        assert len(expected) == count
        assert actual.keys() == expected.keys(), f'{mode} inventory missing/extra: {actual.keys() ^ expected.keys()}'
        for key in expected:
            new, old = copy.deepcopy(actual[key]), copy.deepcopy(expected[key])
            _, kind, _, name = key
            # Exact delivery provenance only; every other metadata leaf is compared.
            if mode == 'seed':
                assert new['metadata']['annotations'].pop(ORIGIN) == 'additions'
            # Only these identities historically dropped chart provenance.
            # Require exact old value AND exact new absence before stripping.
            provenance = {}
            if mode == 'seed' and (kind, name) in {
                ('Service', 'ipam-capi-remote-webhook-service'),
                ('Service', 'ipam-capi-webhook-injector-metrics'),
                ('Deployment', 'ipam-capi-controller-manager'),
                ('ServiceMonitor', 'ipam-capi-webhook-injector'),
            }:
                provenance = {'app.kubernetes.io/managed-by': 'Helm',
                              'helm.sh/chart': 'ipam-capi-remote-1.2.37',
                              'app.kubernetes.io/version': '0.1.0'}
            if mode == 'seed' and (kind, name) == ('ConfigMap', 'ipam-capi-manager-config'):
                provenance = {'app.kubernetes.io/managed-by': 'Helm'}
            for label, value in provenance.items():
                assert old['metadata']['labels'].pop(label) == value
                assert label not in new['metadata'].get('labels', {})
            if kind == 'CustomResourceDefinition':
                if name in CORE:
                    assert 'conversion' not in old['spec']
                    assert new['spec'].pop('conversion') == {'strategy': 'None'}
                    assert LABEL not in new['metadata'].get('labels', {})
                elif name in POOLS:
                    assert old['spec']['conversion'] == OLD_CONVERSION
                    assert new['spec']['conversion'] == NEW_CONVERSION
                    # Both are service-form; strip service.namespace (kube-system vs system
                    # is an expected upstream-vs-overlay difference) before diffing the rest.
                    del old['spec']['conversion']['webhook']['clientConfig']['service']['namespace']
                    del new['spec']['conversion']['webhook']['clientConfig']['service']['namespace']
                    remove_target(new, old)
            elif kind in ADMISSION:
                assert name == ADMISSION[kind]
                remove_target(new, old)
                assert len(new['webhooks']) == len(old['webhooks']) == 4
                for webhook in new['webhooks'] + old['webhooks']:
                    assert 'caBundle' not in webhook['clientConfig']
                # Normalize clientConfig: new overlay has service-form (pre-DDO rewriteWebhookURL);
                # legacy had url-form.  Simulate rewriteWebhookURL here so the rest of each
                # webhook entry can be compared field-by-field.
                URL_PREFIX = 'https://ipam-capi-remote-webhook-service:443'
                for webhook in new['webhooks']:
                    cc = webhook['clientConfig']
                    if 'service' in cc and 'url' not in cc:
                        svc = cc.pop('service')
                        cc['url'] = URL_PREFIX + svc['path']
                for webhook in old['webhooks']:
                    cc = webhook['clientConfig']
                    if 'url' in cc:
                        pass  # already url-form from legacy; keep as-is for comparison
            elif mode == 'shoot' and kind == 'ClusterRole' and name == INJECTOR:
                assert old['rules'] == OLD_RULES
                assert new['rules'] == NEW_RULES, 'target-only injector RBAC differs'
                del new['rules'], old['rules']
            elif mode == 'seed' and kind == 'Deployment' and name == 'ipam-capi-controller-manager':
                new_pod, old_pod = new['spec']['template'], old['spec']['template']
                new_inj = next(c for c in new_pod['spec']['initContainers'] if c['name'] == 'webhook-injector')
                old_inj = next(c for c in old_pod['spec']['initContainers'] if c['name'] == 'webhook-injector')
                assert new_inj['args'] == NEW_ARGS and old_inj['args'] == OLD_ARGS
                del new_inj['args'], old_inj['args']
                assert ORIGIN not in old_pod['metadata'].get('annotations', {})
                assert new_pod['metadata']['annotations'].pop(ORIGIN) == 'additions'
            elif mode == 'seed' and kind == 'ServiceMonitor' and name == 'ipam-capi-webhook-injector':
                assert old['spec'].pop('namespaceSelector') == {'matchNames': [namespace]}
                assert 'namespaceSelector' not in new['spec']
                service = get(candidate['seed'], 'Service', 'ipam-capi-webhook-injector-metrics')
                assert service['metadata']['namespace'] == new['metadata']['namespace'] == namespace
                assert all(service['metadata']['labels'][k] == v for k, v in new['spec']['selector']['matchLabels'].items())
            prune_empty_metadata(new)
            prune_empty_metadata(old)
            assert new == old, f'unreviewed {mode} difference: {key}'


def historical_check(raw):
    path = ROOT / 'tests/crd-baseline.json'
    assert hashlib.sha256(path.read_bytes()).hexdigest() == 'bf7512e5525dae26f3fe1e0429a1c2596d72db0628e2d239beb49c31b93a0b50', 'historical baseline changed'
    baseline = json.loads(path.read_text())
    for mode in ('seed', 'shoot'):
        restored = copy.deepcopy(raw[mode])
        restored = [d for d in restored if (d['kind'], d['metadata']['name']) not in RESTORED[mode]]
        # ADDED is empty after the $patch:delete fix (overlay removes webhook-service itself).
        # The filter is kept for structural symmetry; it is a no-op.
        restored = [d for d in restored if (d['kind'], d['metadata']['name']) not in ADDED[mode]]
        for doc in restored:
            kind, name = doc['kind'], doc['metadata']['name']
            if mode == 'shoot' and (name in POOLS or kind in ADMISSION):
                assert doc['metadata']['labels'].pop(LABEL) == 'ipam-capi-remote'
            if kind == 'CustomResourceDefinition' and name in POOLS:
                assert doc['spec']['conversion'] == NEW_CONVERSION
                # Retrieve old public CA only in memory; never create a certificate artifact.
                patch = yaml.safe_load(git_file(HISTORICAL, PREFIX + f'shoot/patches/conversion-{name.split(".")[0]}.yaml'))
                client = patch['spec']['conversion']['webhook']['clientConfig']
                assert client['service'] is None and client['url'] == URL and client['caBundle']
                # Simulate DDO rewriteWebhookURL (service-form -> url-form) so the fingerprint
                # matches the historical baseline, which was computed against url-form + caBundle.
                svc = doc['spec']['conversion']['webhook']['clientConfig'].pop('service')
                doc['spec']['conversion']['webhook']['clientConfig']['url'] = URL_PREFIX + svc['path']
                doc['spec']['conversion']['webhook']['clientConfig']['caBundle'] = client['caBundle']
            if mode == 'shoot' and kind == 'ClusterRole' and name == INJECTOR:
                assert doc['rules'] == NEW_RULES
                doc['rules'] = copy.deepcopy(OLD_RULES)
            # Simulate DDO rewriteWebhookURL: overlay now sources webhooks in service-form;
            # the historical baseline was computed against url-form.  Normalize here so
            # the fingerprint is comparable to the baseline.
            if kind in ADMISSION:
                _URL_PREFIX = 'https://ipam-capi-remote-webhook-service:443'
                for webhook in doc.get('webhooks', []):
                    cc = webhook.get('clientConfig', {})
                    if 'service' in cc and 'url' not in cc:
                        svc = cc.pop('service')
                        cc['url'] = _URL_PREFIX + svc['path']
        actual = fingerprints(restored)
        assert actual == baseline[mode], f'{mode}: historical fingerprints differ outside reviewed repair'


def negative_tests(raw, legacy, namespace):
    total = 0
    def rejects(changed, label):
        nonlocal total
        try:
            compare(changed, legacy, namespace)
        except (AssertionError, KeyError, StopIteration):
            total += 1
            return
        raise AssertionError(f'accepted mutation: {label}')
    for mode in ('seed', 'shoot'):
        for i, doc in enumerate(raw[mode]):
            # Skip objects that are new in the overlay (not in legacy); their removal
            # is not a parity violation (they're DDO-filtered at deploy time anyway).
            if (doc['kind'], doc['metadata']['name']) in ADDED[mode]:
                continue
            changed = copy.deepcopy(raw)
            changed[mode].pop(i)
            rejects(changed, f'removal {mode}/{doc["metadata"]["name"]}')
            changed = copy.deepcopy(raw)
            changed[mode][i]['metadata'].setdefault('labels', {})['unexpected'] = 'mutation'
            rejects(changed, 'meaningful metadata')
            for label in doc['metadata'].get('labels', {}):
                changed = copy.deepcopy(raw)
                del changed[mode][i]['metadata']['labels'][label]
                rejects(changed, f'removed label {doc["metadata"]["name"]}/{label}')
            if doc['kind'] == 'CustomResourceDefinition':
                changed = copy.deepcopy(raw)
                changed[mode][i]['spec']['versions'][0]['schema']['openAPIV3Schema']['description'] = 'mutated'
                rejects(changed, 'CRD schema')
            if doc['kind'] == 'NetworkPolicy':
                changed = copy.deepcopy(raw)
                changed[mode][i]['spec']['podSelector'] = {}
                rejects(changed, 'broadened policy')
            if doc['kind'] in ('ClusterRole', 'Role'):
                changed = copy.deepcopy(raw)
                changed[mode][i]['rules'][0]['verbs'].append('*')
                rejects(changed, 'broadened RBAC')
            if doc['kind'] in ('ClusterRoleBinding', 'RoleBinding'):
                changed = copy.deepcopy(raw)
                changed[mode][i]['subjects'][0]['name'] = 'wrong-serviceaccount'
                rejects(changed, 'binding subject')
    for name in POOLS + list(ADMISSION.values()):
        kind = 'CustomResourceDefinition' if name in POOLS else next(k for k, v in ADMISSION.items() if v == name)
        for mutation in ('label', 'url', 'ca'):
            changed = copy.deepcopy(raw)
            doc = get(changed['shoot'], kind, name)
            if mutation == 'label':
                doc['metadata']['labels'][LABEL] = 'wrong'
            else:
                client = doc['spec']['conversion']['webhook']['clientConfig'] if name in POOLS else doc['webhooks'][0]['clientConfig']
                client['url' if mutation == 'url' else 'caBundle'] = 'unexpected'
            rejects(changed, f'{name} {mutation}')
    for mutation in ('SAN', 'duplicate selector', 'origin'):
        changed = copy.deepcopy(raw)
        pod = get(changed['seed'], 'Deployment', 'ipam-capi-controller-manager')['spec']['template']
        args = pod['spec']['initContainers'][0]['args']
        if mutation == 'SAN':
            args[4] = '--cert-sans=wrong'
        elif mutation == 'duplicate selector':
            args.append(NEW_ARGS[1])
        else:
            pod['metadata']['annotations'][ORIGIN] = 'wrong'
        rejects(changed, mutation)
    print(f'PASS: {total} negative inventory/schema/metadata/RBAC/network/ownership mutations rejected')


def main(shoot, seed):
    raw = {'shoot': documents(Path(shoot).read_text()), 'seed': documents(Path(seed).read_text())}
    namespace = 'shoot--cp--m-qa-de-200'
    legacy = render(namespace)
    compare(raw, legacy, namespace)
    alternate = 'ipam-alternate-seed'
    compare(raw, render(alternate), alternate)
    historical_check(raw)
    negative_tests(raw, legacy, namespace)
    print('PASS: pinned oracle 13 seed / 21 shoot, guarded migration, both namespace placements, unchanged historical baseline')


if __name__ == '__main__':
    main(*sys.argv[1:])
