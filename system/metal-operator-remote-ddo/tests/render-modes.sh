#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
EXAMPLE_FILE="$CHART_DIR/examples/dualdeploymentoperator-test-qa-de-1.yaml"
TMP_ROOT=${TMPDIR:-/private/var/folders/8m/nyl995ss465f1mn4g6r6lx400000gn/T/opencode}
TMP_DIR=$(mktemp -d "$TMP_ROOT/metal-operator-remote-ddo-render.XXXXXX")
SEED_VALUES_FILE="$TMP_DIR/seed-values.yaml"
SHOOT_VALUES_FILE="$TMP_DIR/shoot-values.yaml"
SEED_RENDER_FILE="$TMP_DIR/seed-render.yaml"
SHOOT_RENDER_FILE="$TMP_DIR/shoot-render.yaml"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log() {
  printf '==> %s\n' "$*"
}

log "Building chart dependencies"
(
  cd "$CHART_DIR"
  helm dependency build .
)

log "Extracting representative values from $(basename "$EXAMPLE_FILE")"
python3 - "$EXAMPLE_FILE" "$SEED_VALUES_FILE" "$SHOOT_VALUES_FILE" <<'PY'
import copy
import pathlib
import sys
import yaml

example_path = pathlib.Path(sys.argv[1])
seed_path = pathlib.Path(sys.argv[2])
shoot_path = pathlib.Path(sys.argv[3])

with example_path.open() as fh:
    data = yaml.safe_load(fh)

helm = data["spec"]["source"]["helm"]
base = helm.get("values") or {}
seed_overlay = helm.get("seedValues") or {}
shoot_overlay = helm.get("shootValues") or {}

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = copy.deepcopy(value)
    return dst

seed_values = merge(copy.deepcopy(base), seed_overlay)
shoot_values = merge(copy.deepcopy(base), shoot_overlay)

seed_path.write_text(yaml.safe_dump(seed_values, sort_keys=False))
shoot_path.write_text(yaml.safe_dump(shoot_values, sort_keys=False))
PY

log "Rendering seed mode"
helm template render-modes "$CHART_DIR" \
  --namespace shoot--cp--test-qa-de-1 \
  --set mode=seed \
  -f "$SEED_VALUES_FILE" \
  > "$SEED_RENDER_FILE"

log "Rendering shoot mode"
helm template render-modes "$CHART_DIR" \
  --namespace kube-system \
  --set mode=shoot \
  -f "$SHOOT_VALUES_FILE" \
  > "$SHOOT_RENDER_FILE"

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

deployment = find_doc(seed_docs, "Deployment", "metal-operator-controller-manager")
expect(deployment is not None, "seed render contains Deployment/metal-operator-controller-manager")
if deployment is not None:
    init_containers = (((deployment.get("spec") or {}).get("template") or {}).get("spec") or {}).get("initContainers") or []
    expect(any(container.get("name") == "webhook-injector" for container in init_containers), "seed Deployment includes webhook-injector initContainer")

expect(find_doc(seed_docs, "Secret", "macdb") is not None, "seed render contains Secret/macdb")
expect(find_doc(seed_docs, "Service", "metal-operator-metal-registry-service") is not None, "seed render contains Service/metal-operator-metal-registry-service")
expect(find_doc(seed_docs, "Service", "metal-operator-remote-webhook-service") is not None, "seed render contains Service/metal-operator-remote-webhook-service")
expect(len(docs_of_kind(seed_docs, "Ingress")) >= 1, "seed render contains an Ingress")
expect(len(docs_of_kind(seed_docs, "NetworkPolicy")) == 6, "seed render contains exactly 6 NetworkPolicy objects")
expect(find_doc(seed_docs, "ConfigMap", "remote-kubeconfig") is not None, "seed render contains ConfigMap/remote-kubeconfig")
expect(len(docs_of_kind(seed_docs, "ValidatingWebhookConfiguration")) == 0, "seed render omits ValidatingWebhookConfiguration")
expect(len(docs_of_kind(seed_docs, "Namespace")) == 0, "seed render omits Namespace")
expect(len(docs_of_kind(seed_docs, "ClusterRole")) == 0, "seed render omits ClusterRole")
expect(len(docs_of_kind(seed_docs, "ClusterRoleBinding")) == 0, "seed render omits ClusterRoleBinding")

crds = docs_of_kind(shoot_docs, "CustomResourceDefinition")
expect(len(crds) >= 1, "shoot render contains at least one CustomResourceDefinition")
vwcs = docs_of_kind(shoot_docs, "ValidatingWebhookConfiguration")
expect(len(vwcs) >= 1, "shoot render contains a ValidatingWebhookConfiguration")
if vwcs:
    ca_bundle_ok = True
    injector_label_absent = True
    for vwc in vwcs:
        labels = (vwc.get("metadata") or {}).get("labels") or {}
        if "dual-deployment-operator.cc.sap/webhook-injector" in labels:
            injector_label_absent = False
        for webhook in vwc.get("webhooks") or []:
            client_config = webhook.get("clientConfig") or {}
            if client_config.get("caBundle") not in (None, ""):
                ca_bundle_ok = False
    expect(ca_bundle_ok, "shoot ValidatingWebhookConfiguration leaves caBundle unset")
    expect(injector_label_absent, "shoot ValidatingWebhookConfiguration leaves injector label absent for later transform")

expect(find_doc(shoot_docs, "Namespace", "metal-servers") is not None, "shoot render contains Namespace/metal-servers")
expect(len(docs_of_kind(shoot_docs, "ClusterRoleBinding")) >= 4, "shoot render contains at least 4 ClusterRoleBinding objects")
expect(find_doc(shoot_docs, "ClusterRole", "metal-api-viewer") is not None, "shoot render contains ClusterRole/metal-api-viewer")
expect(len(docs_of_kind(shoot_docs, "Deployment")) == 0, "shoot render omits Deployment")
expect(len(docs_of_kind(shoot_docs, "Ingress")) == 0, "shoot render omits Ingress")
expect(len(docs_of_kind(shoot_docs, "NetworkPolicy")) == 0, "shoot render omits NetworkPolicy")

for line in passes:
    print(line)

if failures:
    for line in failures:
        print(line, file=sys.stderr)
    sys.exit(1)

print("PASS: all render-mode assertions succeeded")
PY

printf 'PASS: render-modes.sh completed successfully\n'
