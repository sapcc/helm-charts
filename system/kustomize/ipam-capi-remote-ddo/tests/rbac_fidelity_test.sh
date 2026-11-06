#!/usr/bin/env bash
# Compare every shoot RBAC object against pinned legacy, with one exact rule delta.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ipam-rbac-fidelity.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
kustomize build "$DIR/../shoot" > "$WORK/shoot.yaml"
PYTHONDONTWRITEBYTECODE=1 python3 - "$DIR" "$WORK/shoot.yaml" <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from migration_render import documents, place, render
from migration_contract import INJECTOR, NEW_RULES, OLD_RULES, index, DROPPED
kinds={'ServiceAccount','ClusterRole','ClusterRoleBinding','Role','RoleBinding'}
actual=index(d for d in place(documents(Path(sys.argv[2]).read_text()), 'kube-system') if d['kind'] in kinds)
expected=index(d for d in render('shoot--cp--m-qa-de-200')['shoot']
               if d['kind'] in kinds and (d['kind'], d['metadata']['name']) not in DROPPED['shoot'])
assert actual.keys()==expected.keys(), 'RBAC inventory differs'
for key, old in expected.items():
    new=actual[key]
    if key[1]=='ClusterRole' and key[3]==INJECTOR:
        assert old['rules']==OLD_RULES and new['rules']==NEW_RULES
        del old['rules'], new['rules']
    assert old==new, f'unreviewed RBAC delta: {key}'
print('PASS: exact pinned shoot RBAC, including named target writes and broad informer list/watch')
PY
