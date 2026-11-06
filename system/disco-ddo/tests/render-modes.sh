#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TMP_DIR=$(mktemp -d)
SEED_RENDER_FILE="$TMP_DIR/seed-render.yaml"
SHOOT_RENDER_FILE="$TMP_DIR/shoot-render.yaml"
NOOP_RENDER_FILE="$TMP_DIR/noop-render.yaml"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log() {
  printf '==> %s\n' "$*"
}

log "Rendering seed mode"
helm template disco-ddo "$CHART_DIR" \
  --set mode=seed \
  --set apiServerHost=ci.example.com \
  --set openstack.authURL=x \
  --set openstack.regionName=r \
  --set openstack.username=u \
  --set openstack.userDomainName=d \
  --set openstack.password=p \
  --set openstack.projectName=pn \
  --set openstack.projectDomainName=pdn \
  --set openstack.zoneName=z \
  --set record=test \
  > "$SEED_RENDER_FILE"

log "Rendering shoot mode"
helm template disco-ddo "$CHART_DIR" \
  --set mode=shoot \
  > "$SHOOT_RENDER_FILE"

log "Rendering no-mode (expect empty)"
helm template disco-ddo "$CHART_DIR" \
  > "$NOOP_RENDER_FILE"

log "Checking mode contract references in templates"
MODE_REFERENCES=$(grep -RIn '\.Values\.mode' "$CHART_DIR/templates" || true)
if [[ -n "$MODE_REFERENCES" ]]; then
  printf '%s\n' "$MODE_REFERENCES"
fi
MODE_SETTERS=$(grep -RInE '(^|[^[:alnum:]_])set[[:space:]]+[^#\n]*"mode"|(^|[^[:alnum:]_])set[[:space:]]+[^#\n]*\.Values[^#\n]*mode' "$CHART_DIR/templates" || true)
if [[ -n "$MODE_SETTERS" ]]; then
  printf 'FAIL: template attempted to set mode:\n%s\n' "$MODE_SETTERS" >&2
  exit 1
fi

log "Asserting no-mode render is empty"
NOOP_DOC_COUNT=$(python3 -c "
import sys, yaml
with open('$NOOP_RENDER_FILE') as fh:
    docs = [d for d in yaml.safe_load_all(fh) if isinstance(d, dict)]
print(len(docs))
")
if [[ "$NOOP_DOC_COUNT" -ne 0 ]]; then
  printf 'FAIL: no-mode render produced %s document(s); expected 0\n' "$NOOP_DOC_COUNT" >&2
  exit 1
fi
printf 'PASS: no-mode render is empty\n'

log "Asserting exact object inventories"
python3 - "$SEED_RENDER_FILE" "$SHOOT_RENDER_FILE" <<'PY'
import sys
import yaml

seed_path, shoot_path = sys.argv[1:3]

SEED_EXPECTED = sorted([
    # cert-manager and webhook resources are excluded from the default seed render.
    # The DDO operator ClusterRole does not cover cert-manager.io API groups, and
    # Records live on the shoot — the webhook would never fire on the seed.
    # To include them, set certManager.enabled=true / webhook.enabled=true.
    "Deployment/disco-controller-manager",
    "Secret/disco-config",
    "Secret/disco-remote-kubeconfig",
    "ServiceAccount/disco-controller-manager",
])

SHOOT_EXPECTED = sorted([
    "ClusterRole/disco-ddo-manager-role",
    "ClusterRole/disco-ddo-metrics-reader",
    "ClusterRole/disco-ddo-proxy-role",
    "ClusterRoleBinding/disco-ddo-manager-rolebinding",
    "ClusterRoleBinding/disco-ddo-proxy-rolebinding",
    "CustomResourceDefinition/records.disco.stable.sap.cc",
    "Role/disco-leader-election-role",
    "RoleBinding/disco-leader-election-rolebinding",
    "ServiceAccount/disco-controller-manager",
])

def load_docs(path):
    with open(path) as fh:
        return [doc for doc in yaml.safe_load_all(fh) if isinstance(doc, dict)]

def inventory(docs):
    items = []
    for doc in docs:
        kind = doc.get("kind") or "Unknown"
        name = ((doc.get("metadata") or {}).get("name")) or "unnamed"
        items.append(f"{kind}/{name}")
    return sorted(items)

def assert_inventory(label, actual, expected):
    if actual == expected:
        print(f"PASS: {label} exact inventory matches ({len(expected)} objects)")
        return True
    extra   = sorted(set(actual) - set(expected))
    missing = sorted(set(expected) - set(actual))
    print(f"FAIL: {label} inventory mismatch", file=sys.stderr)
    if missing:
        for item in missing:
            print(f"  MISSING: {item}", file=sys.stderr)
    if extra:
        for item in extra:
            print(f"  EXTRA:   {item}", file=sys.stderr)
    return False

seed_docs  = load_docs(seed_path)
shoot_docs = load_docs(shoot_path)

ok = True
ok = assert_inventory("seed",  inventory(seed_docs),  SEED_EXPECTED)  and ok
ok = assert_inventory("shoot", inventory(shoot_docs), SHOOT_EXPECTED) and ok

if not ok:
    sys.exit(1)

print("PASS: all render-mode assertions succeeded")
PY

printf 'PASS: render-modes.sh completed successfully\n'
