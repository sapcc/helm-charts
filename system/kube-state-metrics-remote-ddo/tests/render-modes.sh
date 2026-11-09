#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CHART_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

helm template ksm "$CHART_DIR" --set mode=seed \
  --set config.customResourceStateYaml='kind: CustomResourceStateMetrics' > "$TMP_DIR/seed.yaml"
helm template ksm "$CHART_DIR" --set mode=shoot > "$TMP_DIR/shoot.yaml"
helm template ksm "$CHART_DIR" > "$TMP_DIR/noop.yaml"

if grep -RInE '(^|[^[:alnum:]_])set[[:space:]]+[^#]*"mode"' "$CHART_DIR/templates" >&2; then
  echo "FAIL: template attempted to set mode" >&2
  exit 1
fi

python3 - "$TMP_DIR/seed.yaml" "$TMP_DIR/shoot.yaml" "$TMP_DIR/noop.yaml" <<'PY'
import sys, yaml

def load(p):
    with open(p) as fh:
        return [d for d in yaml.safe_load_all(fh) if isinstance(d, dict)]

def inv(docs):
    return sorted(f"{d['kind']}/{d['metadata']['name']}" for d in docs)

seed, shoot, noop = (load(p) for p in sys.argv[1:4])

SEED_EXPECTED = sorted([
    "ConfigMap/kube-state-metrics-remote-config",
    "Deployment/kube-state-metrics-remote",
    "NetworkPolicy/kube-state-metrics-remote",
    "Secret/kube-state-metrics-remote-kubeconfig",
    "Service/kube-state-metrics-remote-service",
    "ServiceAccount/kube-state-metrics-remote",
])
SHOOT_EXPECTED = sorted([
    "ClusterRole/kube-state-metrics-remote",
    "ClusterRoleBinding/kube-state-metrics-remote",
    "ServiceAccount/kube-state-metrics-remote",
])

def fail(msg):
    print("FAIL: " + msg, file=sys.stderr); sys.exit(1)

if noop: fail(f"no-mode render produced {len(noop)} docs; expected 0")
if inv(seed) != SEED_EXPECTED: fail(f"seed inventory mismatch: {inv(seed)}")
if inv(shoot) != SHOOT_EXPECTED: fail(f"shoot inventory mismatch: {inv(shoot)}")

for d in seed + shoot:
    ann = d['metadata'].get('annotations') or {}
    if ann.get('dual-deployment-operator.cc.sap/origin') != 'additions':
        fail(f"{d['kind']}/{d['metadata']['name']} missing origin: additions stamp")

dep = next(d for d in seed if d['kind'] == 'Deployment')
spec = dep['spec']['template']['spec']
vol = next((v for v in spec['volumes'] if v['name'] == 'remote-kubeconfig'), None)
if not vol or vol['secret']['secretName'] != 'kube-state-metrics-remote-kubeconfig':
    fail("remote-kubeconfig volume missing/wrong secret")
if {(i['key'], i['path']) for i in vol['secret']['items']} != {('token', 'token'), ('bundle.crt', 'ca.crt')}:
    fail("remote-kubeconfig items mismatch")
c = spec['containers'][0]
if not any(m['name'] == 'remote-kubeconfig' and m['mountPath'] == '/var/run/secrets/kubernetes.io/serviceaccount' for m in c['volumeMounts']):
    fail("remote-kubeconfig not mounted at SA path")
if not any(e['name'] == 'KUBERNETES_SERVICE_HOST' and e['value'] for e in c['env']):
    fail("KUBERNETES_SERVICE_HOST missing")
labels = dep['spec']['template']['metadata']['labels']
for k in ('networking.gardener.cloud/to-dns',
          'networking.resources.gardener.cloud/to-kube-apiserver-tcp-443',
          'networking.resources.gardener.cloud/to-virtual-garden-kube-apiserver-tcp-443'):
    if labels.get(k) != 'allowed': fail(f"podLabel {k} missing")
if spec.get('automountServiceAccountToken') is not False: fail("automountServiceAccountToken must be false")

np = next(d for d in seed if d['kind'] == 'NetworkPolicy')
if np['spec']['ingress'][0]['ports'][0]['port'] != 30090: fail("NetworkPolicy port != 30090")
cm = next(d for d in seed if d['kind'] == 'ConfigMap')
if cm['data']['custom-resource-state.yaml'] != 'kind: CustomResourceStateMetrics': fail("ConfigMap scrape spec not injected")

sec = next(d for d in seed if d['kind'] == 'Secret')
if sec['metadata']['annotations']['serviceaccount.resources.gardener.cloud/name'] != 'kube-state-metrics-remote': fail("token-requestor SA name drift")
cr = next(d for d in shoot if d['kind'] == 'ClusterRole')
groups = {g for r in cr['rules'] for g in r['apiGroups']}
for g in ('argora.cloud.sap', 'ipam.cluster.x-k8s.io', 'metal.ironcore.dev', 'core.gardener.cloud'):
    if g not in groups: fail(f"ClusterRole missing group {g}")
print("PASS: all render-mode assertions succeeded")
PY
