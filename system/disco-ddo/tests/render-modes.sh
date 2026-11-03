#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TMP_ROOT=${TMPDIR:-/private/var/folders/8m/nyl995ss465f1mn4g6r6lx400000gn/T/opencode}
TMP_DIR=$(mktemp -d "$TMP_ROOT/disco-ddo-render.XXXXXX")
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

log "Asserting rendered object sets"
python3 - "$SEED_RENDER_FILE" "$SHOOT_RENDER_FILE" <<'PY'
import sys
import yaml

seed_path, shoot_path = sys.argv[1:3]
failures = []
passes = []

def load_docs(path):
    with open(path) as fh:
        return [doc for doc in yaml.safe_load_all(fh) if isinstance(doc, dict)]

seed_docs = load_docs(seed_path)
shoot_docs = load_docs(shoot_path)

def name_of(doc):
    return ((doc.get("metadata") or {}).get("name"))

def docs_of_kind(docs, kind):
    return [doc for doc in docs if doc.get("kind") == kind]

def find_doc(docs, kind, name):
    for doc in docs:
        if doc.get("kind") == kind and name_of(doc) == name:
            return doc
    return None

def expect(condition, message):
    if condition:
        passes.append(f"PASS: {message}")
    else:
        failures.append(f"FAIL: {message}")

# ── SEED assertions ────────────────────────────────────────────────────────────

expect(
    find_doc(seed_docs, "Deployment", "disco-controller-manager") is not None,
    "seed render contains Deployment/disco-controller-manager",
)
expect(
    find_doc(seed_docs, "Secret", "disco-config") is not None,
    "seed render contains Secret/disco-config",
)
expect(
    find_doc(seed_docs, "Issuer", "disco-selfsigned-issuer") is not None,
    "seed render contains Issuer/disco-selfsigned-issuer",
)
expect(
    find_doc(seed_docs, "Certificate", "disco-serving-cert") is not None,
    "seed render contains Certificate/disco-serving-cert",
)
expect(
    find_doc(seed_docs, "Service", "disco-webhook-service") is not None,
    "seed render contains Service/disco-webhook-service",
)
expect(
    find_doc(seed_docs, "MutatingWebhookConfiguration", "disco-ddo-mutating-webhook-configuration") is not None,
    "seed render contains MutatingWebhookConfiguration/disco-ddo-mutating-webhook-configuration",
)
expect(
    find_doc(seed_docs, "Secret", "disco-remote-kubeconfig") is not None,
    "seed render contains Secret/disco-remote-kubeconfig",
)

# SEED must NOT contain shoot-side objects
expect(
    len(docs_of_kind(seed_docs, "CustomResourceDefinition")) == 0,
    "seed render omits CustomResourceDefinition",
)
expect(
    len(docs_of_kind(seed_docs, "ClusterRole")) == 0,
    "seed render omits ClusterRole",
)
expect(
    len(docs_of_kind(seed_docs, "ClusterRoleBinding")) == 0,
    "seed render omits ClusterRoleBinding",
)
expect(
    len(docs_of_kind(seed_docs, "Role")) == 0,
    "seed render omits Role",
)
expect(
    len(docs_of_kind(seed_docs, "RoleBinding")) == 0,
    "seed render omits RoleBinding",
)

# ── SHOOT assertions ───────────────────────────────────────────────────────────

expect(
    find_doc(shoot_docs, "CustomResourceDefinition", "records.disco.stable.sap.cc") is not None,
    "shoot render contains CustomResourceDefinition/records.disco.stable.sap.cc",
)
expect(
    find_doc(shoot_docs, "ServiceAccount", "disco-controller-manager") is not None,
    "shoot render contains ServiceAccount/disco-controller-manager",
)
expect(
    find_doc(shoot_docs, "ClusterRole", "disco-ddo-manager-role") is not None,
    "shoot render contains ClusterRole/disco-ddo-manager-role",
)
expect(
    find_doc(shoot_docs, "ClusterRole", "disco-ddo-proxy-role") is not None,
    "shoot render contains ClusterRole/disco-ddo-proxy-role",
)
expect(
    find_doc(shoot_docs, "ClusterRole", "disco-ddo-metrics-reader") is not None,
    "shoot render contains ClusterRole/disco-ddo-metrics-reader",
)
expect(
    find_doc(shoot_docs, "ClusterRoleBinding", "disco-ddo-manager-rolebinding") is not None,
    "shoot render contains ClusterRoleBinding/disco-ddo-manager-rolebinding",
)
expect(
    find_doc(shoot_docs, "ClusterRoleBinding", "disco-ddo-proxy-rolebinding") is not None,
    "shoot render contains ClusterRoleBinding/disco-ddo-proxy-rolebinding",
)
expect(
    find_doc(shoot_docs, "Role", "disco-leader-election-role") is not None,
    "shoot render contains Role/disco-leader-election-role",
)
expect(
    find_doc(shoot_docs, "RoleBinding", "disco-leader-election-rolebinding") is not None,
    "shoot render contains RoleBinding/disco-leader-election-rolebinding",
)

# SHOOT must NOT contain seed-side objects
expect(
    len(docs_of_kind(shoot_docs, "Deployment")) == 0,
    "shoot render omits Deployment",
)
expect(
    len(docs_of_kind(shoot_docs, "Secret")) == 0,
    "shoot render omits Secret",
)
expect(
    len(docs_of_kind(shoot_docs, "Service")) == 0,
    "shoot render omits Service",
)
expect(
    len(docs_of_kind(shoot_docs, "Issuer")) == 0,
    "shoot render omits Issuer",
)
expect(
    len(docs_of_kind(shoot_docs, "Certificate")) == 0,
    "shoot render omits Certificate",
)
expect(
    len(docs_of_kind(shoot_docs, "MutatingWebhookConfiguration")) == 0,
    "shoot render omits MutatingWebhookConfiguration",
)

# ── Results ────────────────────────────────────────────────────────────────────

for line in passes:
    print(line)

if failures:
    for line in failures:
        print(line, file=sys.stderr)
    sys.exit(1)

print("PASS: all render-mode assertions succeeded")
PY

printf 'PASS: render-modes.sh completed successfully\n'
