"""Mandatory compact render baseline comparison; never refreshes a baseline."""
import copy
import hashlib
import json
from pathlib import Path
import sys

import yaml


def normalize(document):
    document = copy.deepcopy(document)
    document.pop('status', None)
    metadata = document['metadata']
    for key in ('resourceVersion', 'uid', 'generation', 'creationTimestamp',
                'managedFields', 'ownerReferences'):
        metadata.pop(key, None)
    for field in ('labels', 'annotations'):
        entries = metadata.get(field, {})
        for key, value in list(entries.items()):
            if (key.startswith(('meta.helm.sh/', 'resources.gardener.cloud/',
                                'reference.resources.gardener.cloud/'))
                    or (key == 'app.kubernetes.io/managed-by'
                        and value in ('Helm', 'gardener'))):
                del entries[key]
        if not entries:
            metadata.pop(field, None)
    return document


def fingerprints(documents):
    result = {}
    for document in documents:
        if not document:
            continue
        document = normalize(document)
        metadata = document['metadata']
        key = json.dumps([document['apiVersion'], document['kind'],
                          metadata.get('namespace', ''), metadata['name']])
        if key in result:
            raise ValueError(f'duplicate object identity: {key}')
        canonical = json.dumps(document, sort_keys=True, separators=(',', ':'), ensure_ascii=True)
        result[key] = hashlib.sha256(canonical.encode()).hexdigest()
    return result


def main(shoot_path, seed_path, baseline_path):
    baseline = json.loads(Path(baseline_path).read_text())
    failures = []
    for mode, path in (('shoot', shoot_path), ('seed', seed_path)):
        actual = fingerprints(yaml.safe_load_all(Path(path).read_text()))
        expected = baseline[mode]
        for key in sorted(set(actual) | set(expected)):
            if actual.get(key) != expected.get(key):
                failures.append(f'{mode}: parity mismatch {key}')
    if failures:
        raise ValueError('\n'.join(failures))
    print('PASS: mandatory seed/shoot baseline fingerprints match')


if __name__ == '__main__':
    try:
        main(*sys.argv[1:])
    except (ValueError, KeyError, OSError, TypeError, yaml.YAMLError) as error:
        print(f'FAIL: {error}', file=sys.stderr)
        sys.exit(1)
