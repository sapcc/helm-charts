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

# Test 11: seed render contains webhook-injector ClusterRole
if grep -q "^kind: ClusterRole$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains ClusterRole ipam-capi-remote-webhook-injector"
else
  echo "FAIL: seed render should contain ClusterRole ipam-capi-remote-webhook-injector"
  failed=1
fi

# Test 12: seed render contains webhook-injector ClusterRoleBinding
if grep -q "^kind: ClusterRoleBinding$" /tmp/seed_render.yaml && grep -q "name: ipam-capi-remote-webhook-injector" /tmp/seed_render.yaml; then
  echo "PASS: seed render contains ClusterRoleBinding ipam-capi-remote-webhook-injector"
else
  echo "FAIL: seed render should contain ClusterRoleBinding ipam-capi-remote-webhook-injector"
  failed=1
fi

# Test 13: seed render contains ZERO CustomResourceDefinitions
seed_crd_count="$(grep -c '^kind: CustomResourceDefinition$' /tmp/seed_render.yaml || true)"
if [ "$seed_crd_count" -ne 0 ]; then
  echo "FAIL: seed render should contain ZERO CRDs (found $seed_crd_count)"
  failed=1
else
  echo "PASS: seed render contains ZERO CRDs"
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

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All tests PASSED ==="
  exit 0
else
  echo "=== Some tests FAILED ==="
  exit 1
fi
