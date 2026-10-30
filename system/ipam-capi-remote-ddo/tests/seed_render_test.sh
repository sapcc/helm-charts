#!/usr/bin/env bash
# Test: seed render produces Deployment with r7 webhook-injector sidecar and all supporting resources
# This test validates Task 6 deliverables.

set -euo pipefail

# Resolve chart directory relative to this script, so it runs from any cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$TESTS_DIR"

# Ensure kustomize and yq are available
if ! command -v kustomize &> /dev/null; then
  echo "FAIL: kustomize not found in PATH"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  echo "FAIL: yq not found in PATH"
  exit 1
fi

echo "=== Testing seed render from $CHART_DIR ==="

# Track overall test result
failed=0

# Render seed overlay
if ! kustomize build "$CHART_DIR/seed" > /tmp/seed_render_test.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/seed exited non-zero"
  cat /tmp/seed_render_test.yaml
  exit 1
fi

echo "PASS: kustomize build $CHART_DIR/seed exits 0"

# Test 1: Deployment ipam-capi-controller-manager exists
if ! yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .metadata.name' /tmp/seed_render_test.yaml | grep -q "ipam-capi-controller-manager"; then
  echo "FAIL: Deployment ipam-capi-controller-manager not found"
  failed=1
else
  echo "PASS: Deployment ipam-capi-controller-manager exists"
fi

# Test 2: manager container image is overridden to keppel ccloud-gcr-mirror path
manager_image=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.containers[] | select(.name == "manager") | .image' /tmp/seed_render_test.yaml)
if [[ "$manager_image" != "keppel.global.cloud.sap/ccloud-gcr-mirror/k8s-staging-capi-ipam-ic/cluster-api-ipam-in-cluster-controller:v1.1.1" ]]; then
  echo "FAIL: manager image not transformed to keppel mirror (got: $manager_image)"
  failed=1
else
  echo "PASS: manager container image transformed to keppel ccloud-gcr-mirror path"
fi

# Test 3: initContainer webhook-injector exists with correct image
injector_image=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .image' /tmp/seed_render_test.yaml)
if [[ "$injector_image" != "keppel.global.cloud.sap/i-cant-believe-its-not-cloud-infrastructure-dev/webhook-injector:sha-f85df8e3d55165e3b6e1117f6b120624268d0976" ]]; then
  echo "FAIL: webhook-injector image not transformed to keppel mirror (got: $injector_image)"
  failed=1
else
  echo "PASS: webhook-injector image transformed to keppel mirror"
fi

# Test 4: webhook-injector has the EXACT r7 arg set
injector_args=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .args' /tmp/seed_render_test.yaml)

# Required args (must be present)
required_args=(
  "--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig"
  "--target-label=dual-deployment-operator.cc.sap/webhook-injector=ipam-capi-remote"
  "--leader-election-id=ipam-capi-remote-webhook-injector-leader"
  "--cert-secret-name=ipam-capi-remote-cert-secret"
  "--cert-sans=ipam-capi-remote-webhook-service"
  "--rotation-overlap-window=30s"
  "--rotation-gate-timeout=30s"
)

for arg in "${required_args[@]}"; do
  if ! echo "$injector_args" | grep -q -F -- "$arg"; then
    echo "FAIL: webhook-injector missing required arg: $arg"
    failed=1
  fi
done

if [ $failed -eq 0 ]; then
  echo "PASS: webhook-injector has all required r7 args"
fi

# Dead flags (must be absent)
dead_flags=(
  "--webhook-config-name"
  "--managed-resource-label"
  "--external-host"
  "--external-port"
)

for flag in "${dead_flags[@]}"; do
  if echo "$injector_args" | grep -q -F -- "$flag"; then
    echo "FAIL: webhook-injector has dead r7 flag: $flag"
    failed=1
  fi
done

if [ $failed -eq 0 ]; then
  echo "PASS: webhook-injector has no dead r7 flags"
fi

# Test 5: webhook-injector securityContext has correct values
injector_sc_runAsNonRoot=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .securityContext.runAsNonRoot' /tmp/seed_render_test.yaml)
injector_sc_runAsUser=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .securityContext.runAsUser' /tmp/seed_render_test.yaml)

if [[ "$injector_sc_runAsNonRoot" != "true" ]] || [[ "$injector_sc_runAsUser" != "65532" ]]; then
  echo "FAIL: webhook-injector securityContext incorrect (runAsNonRoot=$injector_sc_runAsNonRoot, runAsUser=$injector_sc_runAsUser)"
  failed=1
else
  echo "PASS: webhook-injector securityContext correct"
fi

# Test 6: pod has 7 gardener networking labels
gardener_labels=(
  "networking.gardener.cloud/to-dns"
  "networking.gardener.cloud/to-private-networks"
  "networking.gardener.cloud/to-public-networks"
  "networking.gardener.cloud/to-runtime-apiserver"
  "networking.resources.gardener.cloud/to-all-istio-ingresses-istio-ingressgateway-tcp-9443"
  "networking.resources.gardener.cloud/to-kube-apiserver-tcp-443"
  "networking.resources.gardener.cloud/to-virtual-garden-kube-apiserver-tcp-443"
)

pod_labels=$(yq eval 'select(.kind == "Deployment" and .metadata.name == "ipam-capi-controller-manager") | .spec.template.metadata.labels | keys' /tmp/seed_render_test.yaml)

for label in "${gardener_labels[@]}"; do
  if ! echo "$pod_labels" | grep -q -F -- "$label"; then
    echo "FAIL: pod template missing gardener networking label: $label"
    failed=1
  fi
done

if [ $failed -eq 0 ]; then
  echo "PASS: pod template has all 7 gardener networking labels"
fi

# Test 7: webhook Service ipam-capi-remote-webhook-service exists with correct ports
if ! yq eval 'select(.kind == "Service" and .metadata.name == "ipam-capi-remote-webhook-service") | .metadata.name' /tmp/seed_render_test.yaml | grep -q "ipam-capi-remote-webhook-service"; then
  echo "FAIL: Service ipam-capi-remote-webhook-service not found"
  failed=1
else
  echo "PASS: Service ipam-capi-remote-webhook-service exists"
  
  # Check port mapping
  svc_port=$(yq eval 'select(.kind == "Service" and .metadata.name == "ipam-capi-remote-webhook-service") | .spec.ports[0].port' /tmp/seed_render_test.yaml)
  svc_targetPort=$(yq eval 'select(.kind == "Service" and .metadata.name == "ipam-capi-remote-webhook-service") | .spec.ports[0].targetPort' /tmp/seed_render_test.yaml)
  
  if [[ "$svc_port" != "443" ]] || [[ "$svc_targetPort" != "9443" ]]; then
    echo "FAIL: Service port mapping incorrect (port=$svc_port, targetPort=$svc_targetPort)"
    failed=1
  else
    echo "PASS: Service port mapping correct (443->9443)"
  fi
fi

# Test 8: token-requestor Secret ipam-capi-remote-kubeconfig has gardener labels/annotations
secret_purpose=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.labels."resources.gardener.cloud/purpose"' /tmp/seed_render_test.yaml)
secret_class=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.labels."resources.gardener.cloud/class"' /tmp/seed_render_test.yaml)
secret_sa_annotation=$(yq eval 'select(.kind == "Secret" and .metadata.name == "ipam-capi-remote-kubeconfig") | .metadata.annotations."serviceaccount.resources.gardener.cloud/name"' /tmp/seed_render_test.yaml)

if [[ "$secret_purpose" != "token-requestor" ]] || [[ "$secret_class" != "shoot" ]] || [[ "$secret_sa_annotation" != "ipam-capi-controller-manager" ]]; then
  echo "FAIL: token-requestor Secret missing/incorrect gardener labels/annotations"
  failed=1
else
  echo "PASS: token-requestor Secret has correct gardener labels/annotations"
fi

# Test 9: ALL objects carry dual-deployment-operator.cc.sap/origin: additions annotation
objects_without_origin=$(yq eval 'select(.metadata.annotations."dual-deployment-operator.cc.sap/origin" != "additions") | .kind + "/" + .metadata.name' /tmp/seed_render_test.yaml)

if [ -n "$objects_without_origin" ]; then
  echo "FAIL: Some objects missing origin annotation:"
  echo "$objects_without_origin"
  failed=1
else
  echo "PASS: All objects carry dual-deployment-operator.cc.sap/origin: additions annotation"
fi

# Cluster-scoped bindings are not rewritten by DDO ApplyNamespace.
injector_subject=$(yq eval 'select(.kind == "ClusterRoleBinding" and .metadata.name == "ipam-capi-remote-webhook-injector") | .subjects[] | select(.kind == "ServiceAccount" and .name == "ipam-capi-remote-webhook-injector") | .namespace' /tmp/seed_render_test.yaml)
if [[ "$injector_subject" != "kube-system" ]]; then
  echo "FAIL: webhook-injector ClusterRoleBinding subject namespace must be kube-system (got: $injector_subject)"
  failed=1
else
  echo "PASS: webhook-injector ClusterRoleBinding subject namespace is kube-system"
fi

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All seed render tests PASSED ==="
  exit 0
else
  echo "=== Some seed render tests FAILED ==="
  exit 1
fi
