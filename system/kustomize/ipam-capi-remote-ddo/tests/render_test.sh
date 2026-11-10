#!/usr/bin/env bash
# Test: overlay tree renders cleanly and carries the required annotations
# This file is established here and extended by later tasks with additional assertions.

set -euo pipefail

# Resolve chart directory relative to this script, so it runs from any cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$TESTS_DIR"

# Ensure kustomize is available
if ! command -v kustomize &> /dev/null; then
  echo "FAIL: kustomize not found in PATH"
  exit 1
fi

echo "=== Rendering overlay tree from $CHART_DIR ==="

# Helper: run assertion and print result
assert() {
  local name="$1"
  local cmd="$2"
  
  if eval "$cmd" > /dev/null 2>&1; then
    echo "PASS: $name"
    return 0
  else
    echo "FAIL: $name"
    return 1
  fi
}

# Track overall test result
failed=0

# Test 1: seed overlay builds to exit 0
if ! kustomize build "$CHART_DIR/seed" > /tmp/seed_render.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/seed exited non-zero"
  cat /tmp/seed_render.yaml
  failed=1
else
  echo "PASS: kustomize build $CHART_DIR/seed exits 0"
fi

# Test 2: shoot overlay builds to exit 0
if ! kustomize build "$CHART_DIR/shoot" > /tmp/shoot_render.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/shoot exited non-zero"
  cat /tmp/shoot_render.yaml
  failed=1
else
  echo "PASS: kustomize build $CHART_DIR/shoot exits 0"
fi

# Test 3: seed render contains Deployment ipam-capi-controller-manager
if grep -q "^kind: Deployment$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-controller-manager" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains Deployment ipam-capi-controller-manager"
else
  echo "FAIL: seed render should contain Deployment ipam-capi-controller-manager"
  failed=1
fi

# Test 4: shoot render contains all 7 vendored CRDs
crd_count="$(grep -c '^kind: CustomResourceDefinition$' /tmp/shoot_render.yaml || true)"
if [ "$crd_count" -ne 7 ]; then
  echo "FAIL: shoot render should contain 7 CRDs (found $crd_count)"
  failed=1
else
  echo "PASS: shoot render contains 7 CRDs"
fi

# Test 5: additions/seed/kustomization.yaml contains the origin annotation
if grep -q 'dual-deployment-operator.cc.sap/origin: additions' "$CHART_DIR/additions/seed/kustomization.yaml"; then
  echo "PASS: additions/seed/kustomization.yaml has origin annotation"
else
  echo "FAIL: additions/seed/kustomization.yaml missing origin annotation"
  failed=1
fi

# Test 6: additions/shoot/kustomization.yaml contains the origin annotation
if grep -q 'dual-deployment-operator.cc.sap/origin: additions' "$CHART_DIR/additions/shoot/kustomization.yaml"; then
  echo "PASS: additions/shoot/kustomization.yaml has origin annotation"
else
  echo "FAIL: additions/shoot/kustomization.yaml missing origin annotation"
  failed=1
fi

# === MODE ISOLATION GATE ===

echo ""
echo "=== Mode isolation gate: seed render ==="

# Test 7: seed render contains Service ipam-capi-remote-webhook-service
if grep -q "^kind: Service$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-service" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains Service ipam-capi-remote-webhook-service"
else
  echo "FAIL: seed render should contain Service ipam-capi-remote-webhook-service"
  failed=1
fi

# Test 8: seed render contains webhook-injector ServiceAccount
if grep -q "^kind: ServiceAccount$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains ServiceAccount ipam-capi-remote-webhook-injector"
else
  echo "FAIL: seed render should contain ServiceAccount ipam-capi-remote-webhook-injector"
  failed=1
fi

# Test 9: seed render contains webhook-injector Role
if grep -q "^kind: Role$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains Role ipam-capi-remote-webhook-injector"
else
  echo "FAIL: seed render should contain webhook-injector Role"
  failed=1
fi

# Test 10: seed render contains webhook-injector RoleBinding
if grep -q "^kind: RoleBinding$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains RoleBinding ipam-capi-remote-webhook-injector"
else
  echo "FAIL: seed render should contain webhook-injector RoleBinding"
  failed=1
fi

# Test 11: seed render contains ZERO webhook-injector ClusterRole (dropped; injector uses target kubeconfig)
if grep -q "^kind: ClusterRole$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "FAIL: seed render should NOT contain ClusterRole ipam-capi-remote-webhook-injector"
  failed=1
else
  echo "PASS: seed render contains ZERO ClusterRole ipam-capi-remote-webhook-injector"
fi

# Test 12: seed render contains ZERO webhook-injector ClusterRoleBinding (dropped)
if grep -q "^kind: ClusterRoleBinding$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "FAIL: seed render should NOT contain ClusterRoleBinding ipam-capi-remote-webhook-injector"
  failed=1
else
  echo "PASS: seed render contains ZERO ClusterRoleBinding ipam-capi-remote-webhook-injector"
fi

# Test 13: seed render contains ZERO CustomResourceDefinitions
seed_crd_count="$(grep -c '^kind: CustomResourceDefinition$' /tmp/seed_render.yaml || true)"
if [ "$seed_crd_count" -ne 0 ]; then
  echo "FAIL: seed render should contain ZERO CRDs (found $seed_crd_count)"
  failed=1
else
  echo "PASS: seed render contains ZERO CRDs"
fi

# Webhook configurations and controller RBAC belong only to shoot.
if ! python3 - /tmp/seed_render.yaml <<'PY'
import sys
import yaml

documents = [doc for doc in yaml.safe_load_all(open(sys.argv[1])) if doc]
failed = False
for kind, name in (
    ("MutatingWebhookConfiguration", None),
    ("ValidatingWebhookConfiguration", None),
    ("ClusterRole", "ipam-capi-manager-role"),
):
    present = any(doc.get("kind") == kind
                  and (name is None or doc.get("metadata", {}).get("name") == name)
                  for doc in documents)
    label = f"{kind} {name}" if name else kind
    print(f"{'FAIL' if present else 'PASS'}: seed render contains ZERO {label}")
    failed |= present
sys.exit(1 if failed else 0)
PY
then
  failed=1
fi

echo ""
echo "=== Mode isolation gate: shoot render ==="

# Test 14: shoot render contains all 7 specific CRDs by name
required_crds=(
  "globalinclusterippools.ipam.cluster.x-k8s.io"
  "globalinclusterprefixpools.ipam.cluster.x-k8s.io"
  "inclusterippools.ipam.cluster.x-k8s.io"
  "inclusterprefixpools.ipam.cluster.x-k8s.io"
  "ipaddresses.ipam.cluster.x-k8s.io"
  "ipaddressclaims.ipam.cluster.x-k8s.io"
  "clusters.cluster.x-k8s.io"
)

for crd_name in "${required_crds[@]}"; do
  if grep -q "name: $crd_name$" /tmp/shoot_render.yaml; then
    echo "PASS: shoot render contains CRD $crd_name"
  else
    echo "FAIL: shoot render should contain CRD $crd_name"
    failed=1
  fi
done

# Test 15: shoot render contains controller ServiceAccount ipam-capi-controller-manager
if grep -q "^kind: ServiceAccount$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-controller-manager" /tmp/shoot_render.yaml; then
  echo "PASS: shoot render contains ServiceAccount ipam-capi-controller-manager"
else
  echo "FAIL: shoot render should contain ServiceAccount ipam-capi-controller-manager"
  failed=1
fi

# Test 16: shoot render contains controller manager ClusterRole
if grep -q "^kind: ClusterRole$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-manager-role" /tmp/shoot_render.yaml; then
  echo "PASS: shoot render contains ClusterRole ipam-capi-manager-role"
else
  echo "FAIL: shoot render should contain ClusterRole ipam-capi-manager-role"
  failed=1
fi

# Test 17: shoot render contains cross-operator metal ClusterRoleBinding
if grep -q "^kind: ClusterRoleBinding$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-metal-rolebinding" /tmp/shoot_render.yaml; then
  echo "PASS: shoot render contains ClusterRoleBinding ipam-capi-metal-rolebinding (cross-operator)"
else
  echo "FAIL: shoot render should contain cross-operator ClusterRoleBinding ipam-capi-metal-rolebinding"
  failed=1
fi

# Test 18: shoot render contains MutatingWebhookConfiguration
if grep -q "^kind: MutatingWebhookConfiguration$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-remote-mutating-webhook-configuration" /tmp/shoot_render.yaml; then
  echo "PASS: shoot render contains MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration"
else
  echo "FAIL: shoot render should contain MutatingWebhookConfiguration"
  failed=1
fi

# Test 19: shoot render contains ValidatingWebhookConfiguration
if grep -q "^kind: ValidatingWebhookConfiguration$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-remote-validating-webhook-configuration" /tmp/shoot_render.yaml; then
  echo "PASS: shoot render contains ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration"
else
  echo "FAIL: shoot render should contain ValidatingWebhookConfiguration"
  failed=1
fi

# Test 20: shoot render contains ZERO Deployment
shoot_deployment_count="$(grep -c '^kind: Deployment$' /tmp/shoot_render.yaml || true)"
if [ "$shoot_deployment_count" -ne 0 ]; then
  echo "FAIL: shoot render should contain ZERO Deployments (found $shoot_deployment_count)"
  failed=1
else
  echo "PASS: shoot render contains ZERO Deployments"
fi

# Test 21: shoot render contains ZERO Service named ipam-capi-remote-webhook-service
if grep -q "^kind: Service$" /tmp/shoot_render.yaml && grep -q "name: ipam-capi-remote-webhook-service" /tmp/shoot_render.yaml; then
  echo "FAIL: shoot render should NOT contain Service ipam-capi-remote-webhook-service"
  failed=1
else
  echo "PASS: shoot render contains ZERO Service ipam-capi-remote-webhook-service"
fi

# Test 22: shoot render contains ZERO leader-election RBAC (manager runs --leader-elect=false)
if ! python3 - /tmp/shoot_render.yaml <<'PY'
import sys, yaml
docs = [d for d in yaml.safe_load_all(open(sys.argv[1])) if d]
failed = False
for kind, name in (
    ("ClusterRole", "ipam-capi-leader-election-role"),
    ("ClusterRoleBinding", "ipam-capi-leader-election-rolebinding"),
    ("ClusterRole", "ipam-capi-remote-leader-election-role"),
    ("ClusterRoleBinding", "ipam-capi-remote-leader-election-rolebinding"),
):
    present = any(d.get("kind") == kind and d.get("metadata", {}).get("name") == name for d in docs)
    print(f"{'FAIL' if present else 'PASS'}: shoot render contains ZERO {kind} {name}")
    failed |= present
sys.exit(1 if failed else 0)
PY
then
  failed=1
fi

# Test 23: regression guard — shoot still has injector ClusterRole + metal bindings + core controller bindings
if ! python3 - /tmp/shoot_render.yaml <<'PY'
import sys, yaml
docs = [d for d in yaml.safe_load_all(open(sys.argv[1])) if d]
failed = False
for kind, name in (
    ("ClusterRole", "ipam-capi-remote-webhook-injector"),
    ("ClusterRoleBinding", "ipam-capi-remote-webhook-injector-rolebinding"),
    ("ClusterRoleBinding", "ipam-capi-metal-rolebinding"),
    ("ClusterRoleBinding", "ipam-capi-metal-admin-rolebinding"),
    ("ClusterRoleBinding", "ipam-capi-manager-rolebinding"),
    ("ClusterRoleBinding", "ipam-capi-proxy-rolebinding"),
):
    present = any(d.get("kind") == kind and d.get("metadata", {}).get("name") == name for d in docs)
    print(f"{'PASS' if present else 'FAIL'}: shoot render retains {kind} {name}")
    failed |= not present
sys.exit(1 if failed else 0)
PY
then
  failed=1
fi

# ============================================================================
# SEED DEPLOYMENT DETAIL (folded from retired seed_render_test.sh)
# Deep assertions on the seed Deployment: image overrides, the exact r7 injector
# arg set, securityContext, gardener pod labels, webhook Service ports, the
# token-requestor Secret, the origin annotation on every object, and the
# namespaced-only injector RBAC (SA/Role/RoleBinding present; ClusterRole/
# ClusterRoleBinding absent).  Reuses /tmp/seed_render.yaml from Test 1 (requires yq).
# ============================================================================
echo ""
echo "=== Seed Deployment detail ==="

if ! command -v yq &> /dev/null; then
  echo "FAIL: yq not found in PATH (required for seed Deployment detail)"
  failed=1
else
  SEED=/tmp/seed_render.yaml

  # manager container image overridden to keppel ccloud-gcr-mirror path
  manager_image=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.containers[] | select(.name == "manager") | .image' "$SEED")
  if [[ "$manager_image" != "keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1" ]]; then
    echo "FAIL: manager image not transformed to keppel mirror (got: $manager_image)"
    failed=1
  else
    echo "PASS: manager container image transformed to keppel ccloud-gcr-mirror path"
  fi

  # initContainer webhook-injector image overridden to keppel mirror
  injector_image=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .image' "$SEED")
  if [[ "$injector_image" != "keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976" ]]; then
    echo "FAIL: webhook-injector image not transformed to keppel mirror (got: $injector_image)"
    failed=1
  else
    echo "PASS: webhook-injector image transformed to keppel mirror"
  fi

  # webhook-injector has the EXACT r7 arg set (required present)
  injector_args=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .args' "$SEED")
  required_args=(
    "--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig"
    "--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote"
    "--leader-election-id=ipam-capi-remote-webhook-injector-leader"
    "--cert-secret-name=ipam-capi-remote-cert-secret"
    "--cert-sans=ipam-capi-remote-webhook-service"
    "--rotation-overlap-window=30s"
    "--rotation-gate-timeout=30s"
  )
  injector_args_ok=1
  for arg in "${required_args[@]}"; do
    if ! echo "$injector_args" | grep -q -F -- "$arg"; then
      echo "FAIL: webhook-injector missing required arg: $arg"
      failed=1; injector_args_ok=0
    fi
  done
  [ "$injector_args_ok" -eq 1 ] && echo "PASS: webhook-injector has all required r7 args"

  # Dead flags must be absent
  dead_flags=(
    "--webhook-config-name"
    "--managed-resource-label"
    "--external-host"
    "--external-port"
  )
  dead_flags_ok=1
  for flag in "${dead_flags[@]}"; do
    if echo "$injector_args" | grep -q -F -- "$flag"; then
      echo "FAIL: webhook-injector has dead r7 flag: $flag"
      failed=1; dead_flags_ok=0
    fi
  done
  [ "$dead_flags_ok" -eq 1 ] && echo "PASS: webhook-injector has no dead r7 flags"

  # webhook-injector securityContext
  injector_sc_runAsNonRoot=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .securityContext.runAsNonRoot' "$SEED")
  injector_sc_runAsUser=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .securityContext.runAsUser' "$SEED")
  if [[ "$injector_sc_runAsNonRoot" != "true" ]] || [[ "$injector_sc_runAsUser" != "65532" ]]; then
    echo "FAIL: webhook-injector securityContext incorrect (runAsNonRoot=$injector_sc_runAsNonRoot, runAsUser=$injector_sc_runAsUser)"
    failed=1
  else
    echo "PASS: webhook-injector securityContext correct"
  fi

  # pod has 7 gardener networking labels
  gardener_labels=(
    "networking.gardener.cloud/to-dns"
    "networking.gardener.cloud/to-private-networks"
    "networking.gardener.cloud/to-public-networks"
    "networking.gardener.cloud/to-runtime-apiserver"
    "networking.resources.gardener.cloud/to-all-istio-ingresses-istio-ingressgateway-tcp-9443"
    "networking.resources.gardener.cloud/to-kube-apiserver-tcp-443"
    "networking.resources.gardener.cloud/to-virtual-garden-kube-apiserver-tcp-443"
  )
  pod_labels=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.metadata.labels | keys' "$SEED")
  gardener_ok=1
  for label in "${gardener_labels[@]}"; do
    if ! echo "$pod_labels" | grep -q -F -- "$label"; then
      echo "FAIL: pod template missing gardener networking label: $label"
      failed=1; gardener_ok=0
    fi
  done
  [ "$gardener_ok" -eq 1 ] && echo "PASS: pod template has all 7 gardener networking labels"

  # webhook Service port mapping 443->9443
  svc_port=$(yq eval 'select(.kind == "Service" and .metadata.name == "ipam-capi-remote-webhook-service") | .spec.ports[0].port' "$SEED")
  svc_targetPort=$(yq eval 'select(.kind == "Service" and .metadata.name == "ipam-capi-remote-webhook-service") | .spec.ports[0].targetPort' "$SEED")
  if [[ "$svc_port" != "443" ]] || [[ "$svc_targetPort" != "9443" ]]; then
    echo "FAIL: Service port mapping incorrect (port=$svc_port, targetPort=$svc_targetPort)"
    failed=1
  else
    echo "PASS: webhook Service port mapping correct (443->9443)"
  fi

  # token-requestor Secret gardener labels/annotations
  secret_purpose=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.labels."resources.gardener.cloud/purpose"' "$SEED")
  secret_class=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.labels."resources.gardener.cloud/class"' "$SEED")
  secret_sa_annotation=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.annotations."serviceaccount.resources.gardener.cloud/name"' "$SEED")
  if [[ "$secret_purpose" != "token-requestor" ]] || [[ "$secret_class" != "shoot" ]] || [[ "$secret_sa_annotation" != "ipam-capi-controller-manager" ]]; then
    echo "FAIL: token-requestor Secret missing/incorrect gardener labels/annotations"
    failed=1
  else
    echo "PASS: token-requestor Secret has correct gardener labels/annotations"
  fi

  # ALL objects carry the origin: additions annotation
  objects_without_origin=$(yq eval 'select(.metadata.annotations."dual-deployment-operator.cc.sap/origin" != "additions") | .kind + "/" + .metadata.name' "$SEED")
  if [ -n "$objects_without_origin" ]; then
    echo "FAIL: Some seed objects missing origin annotation:"
    echo "$objects_without_origin"
    failed=1
  else
    echo "PASS: All seed objects carry dual-deployment-operator.cc.sap/origin: additions annotation"
  fi

  # injector seed RBAC namespaced-only: SA + Role + RoleBinding present
  for kind in ServiceAccount Role RoleBinding; do
    if ! yq eval "select(.kind == \"$kind\" and .metadata.name == \"ipam-capi-remote-webhook-injector\") | .metadata.name" "$SEED" | grep -q "ipam-capi-remote-webhook-injector"; then
      echo "FAIL: webhook-injector seed $kind not found"
      failed=1
    else
      echo "PASS: webhook-injector seed $kind present"
    fi
  done

  # dead seed-side injector ClusterRole + ClusterRoleBinding ABSENT
  for kind in ClusterRole ClusterRoleBinding; do
    if yq eval "select(.kind == \"$kind\" and .metadata.name == \"ipam-capi-remote-webhook-injector\") | .metadata.name" "$SEED" | grep -q "ipam-capi-remote-webhook-injector"; then
      echo "FAIL: dead webhook-injector seed $kind should have been removed"
      failed=1
    else
      echo "PASS: dead webhook-injector seed $kind absent"
    fi
  done
fi

# ============================================================================
# POOL ABSENCE + EXAMPLE STRUCTURE (folded from retired no_pool_test.sh)
# a-qa-de-200 carries no pools, so the shoot render must contain ZERO
# GlobalInClusterIPPool objects.  The committed pools.example.yaml template must
# stay well-formed (single spec:, correct kind/namespace/apiVersion).
# Reuses /tmp/shoot_render.yaml from Test 2.
# ============================================================================
echo ""
echo "=== Pool absence + example structure ==="

# shoot render contains ZERO GlobalInClusterIPPool objects
pool_count="$(grep -c '^kind: GlobalInClusterIPPool$' /tmp/shoot_render.yaml || true)"
if [ "$pool_count" -ne 0 ]; then
  echo "FAIL: shoot render should contain 0 GlobalInClusterIPPool objects (found $pool_count)"
  failed=1
else
  echo "PASS: shoot render contains 0 GlobalInClusterIPPool objects"
fi

POOLS_EXAMPLE="$CHART_DIR/additions/shoot/pools.example.yaml"
if [ ! -f "$POOLS_EXAMPLE" ]; then
  echo "FAIL: pools.example.yaml does not exist"
  failed=1
else
  echo "PASS: pools.example.yaml exists"

  if ! python3 -c "import yaml; yaml.safe_load(open('$POOLS_EXAMPLE'))" 2>&1; then
    echo "FAIL: pools.example.yaml is not valid YAML"
    failed=1
  else
    echo "PASS: pools.example.yaml is valid YAML"

    spec_count="$(grep -c '^spec:' "$POOLS_EXAMPLE" || true)"
    if [ "$spec_count" -ne 1 ]; then
      echo "FAIL: pools.example.yaml should have exactly 1 'spec:' key (found $spec_count) - regression on duplicate spec bug"
      failed=1
    else
      echo "PASS: pools.example.yaml has exactly 1 'spec:' key (no duplicate bug)"
    fi

    if ! grep -q '^kind: GlobalInClusterIPPool$' "$POOLS_EXAMPLE"; then
      echo "FAIL: pools.example.yaml should have kind: GlobalInClusterIPPool"
      failed=1
    else
      echo "PASS: pools.example.yaml has kind: GlobalInClusterIPPool"
    fi

    if ! grep -q 'namespace: metal-servers' "$POOLS_EXAMPLE"; then
      echo "FAIL: pools.example.yaml should have namespace: metal-servers"
      failed=1
    else
      echo "PASS: pools.example.yaml has namespace: metal-servers"
    fi

    if ! grep -q 'apiVersion: ipam.cluster.x-k8s.io/v1alpha2' "$POOLS_EXAMPLE"; then
      echo "FAIL: pools.example.yaml should have apiVersion: ipam.cluster.x-k8s.io/v1alpha2"
      failed=1
    else
      echo "PASS: pools.example.yaml has apiVersion: ipam.cluster.x-k8s.io/v1alpha2"
    fi
  fi
fi

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All render tests PASSED ==="
  exit 0
else
  echo "=== Some tests FAILED ==="
  exit 1
fi
