#!/usr/bin/env bash
# Test: shoot render contains both webhook configs with exact contract fields
set -euo pipefail

# Resolve chart directory relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure kustomize and yq are available
command -v kustomize >/dev/null || { echo "FAIL: kustomize not found in PATH"; exit 1; }
command -v yq >/dev/null || { echo "FAIL: yq not found in PATH"; exit 1; }

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ipam-webhook-parity.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# Render shoot overlay
kustomize build "$OVERLAY_DIR/shoot" > "$WORK_DIR/shoot.yaml"

# Track failures
failed=0

# Test 1: MutatingWebhookConfiguration present
if yq eval 'select(.kind == "MutatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-mutating-webhook-configuration")' "$WORK_DIR/shoot.yaml" | grep -q "kind:"; then
  echo "PASS: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration present"
else
  echo "FAIL: MutatingWebhookConfiguration ipam-capi-remote-mutating-webhook-configuration missing"
  failed=1
fi

# Test 2: ValidatingWebhookConfiguration present
if yq eval 'select(.kind == "ValidatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-validating-webhook-configuration")' "$WORK_DIR/shoot.yaml" | grep -q "kind:"; then
  echo "PASS: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration present"
else
  echo "FAIL: ValidatingWebhookConfiguration ipam-capi-remote-validating-webhook-configuration missing"
  failed=1
fi

# Test 3: Exactly 4 mutating webhooks
mutating_count=$(yq eval 'select(.kind == "MutatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-mutating-webhook-configuration") | .webhooks | length' "$WORK_DIR/shoot.yaml")
if [ "$mutating_count" = "4" ]; then
  echo "PASS: MutatingWebhookConfiguration has exactly 4 webhooks"
else
  echo "FAIL: MutatingWebhookConfiguration has $mutating_count webhooks (expected 4)"
  failed=1
fi

# Test 4: Exactly 4 validating webhooks
validating_count=$(yq eval 'select(.kind == "ValidatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-validating-webhook-configuration") | .webhooks | length' "$WORK_DIR/shoot.yaml")
if [ "$validating_count" = "4" ]; then
  echo "PASS: ValidatingWebhookConfiguration has exactly 4 webhooks"
else
  echo "FAIL: ValidatingWebhookConfiguration has $validating_count webhooks (expected 4)"
  failed=1
fi

# Test 5: Mutating webhook names
expected_mutating_names=(
  "default.globalinclusterippool.ipam.cluster.x-k8s.io"
  "default.globalinclusterprefixpool.ipam.cluster.x-k8s.io"
  "default.inclusterippool.ipam.cluster.x-k8s.io"
  "default.inclusterprefixpool.ipam.cluster.x-k8s.io"
)
for name in "${expected_mutating_names[@]}"; do
  if yq eval "select(.kind == \"MutatingWebhookConfiguration\" and .metadata.name == \"ipam-capi-remote-mutating-webhook-configuration\") | .webhooks[] | select(.name == \"$name\")" "$WORK_DIR/shoot.yaml" | grep -q "name:"; then
    echo "PASS: Mutating webhook $name present"
  else
    echo "FAIL: Mutating webhook $name missing"
    failed=1
  fi
done

# Test 6: Validating webhook names
expected_validating_names=(
  "validation.globalinclusterippool.ipam.cluster.x-k8s.io"
  "validation.globalinclusterprefixpool.ipam.cluster.x-k8s.io"
  "validation.inclusterippool.ipam.cluster.x-k8s.io"
  "validation.inclusterprefixpool.ipam.cluster.x-k8s.io"
)
for name in "${expected_validating_names[@]}"; do
  if yq eval "select(.kind == \"ValidatingWebhookConfiguration\" and .metadata.name == \"ipam-capi-remote-validating-webhook-configuration\") | .webhooks[] | select(.name == \"$name\")" "$WORK_DIR/shoot.yaml" | grep -q "name:"; then
    echo "PASS: Validating webhook $name present"
  else
    echo "FAIL: Validating webhook $name missing"
    failed=1
  fi
done

# Test 7: Exact mutating webhook URLs
expected_mutating_urls=(
  "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterippool"
  "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterprefixpool"
  "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-inclusterippool"
  "https://ipam-capi-remote-webhook-service:443/mutate-ipam-cluster-x-k8s-io-v1alpha2-inclusterprefixpool"
)
for url in "${expected_mutating_urls[@]}"; do
  if yq eval "select(.kind == \"MutatingWebhookConfiguration\" and .metadata.name == \"ipam-capi-remote-mutating-webhook-configuration\") | .webhooks[].clientConfig.url" "$WORK_DIR/shoot.yaml" | grep -qF "$url"; then
    echo "PASS: Mutating webhook URL $url present"
  else
    echo "FAIL: Mutating webhook URL $url missing"
    failed=1
  fi
done

# Test 8: Exact validating webhook URLs
expected_validating_urls=(
  "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterippool"
  "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-globalinclusterprefixpool"
  "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-inclusterippool"
  "https://ipam-capi-remote-webhook-service:443/validate-ipam-cluster-x-k8s-io-v1alpha2-inclusterprefixpool"
)
for url in "${expected_validating_urls[@]}"; do
  if yq eval "select(.kind == \"ValidatingWebhookConfiguration\" and .metadata.name == \"ipam-capi-remote-validating-webhook-configuration\") | .webhooks[].clientConfig.url" "$WORK_DIR/shoot.yaml" | grep -qF "$url"; then
    echo "PASS: Validating webhook URL $url present"
  else
    echo "FAIL: Validating webhook URL $url missing"
    failed=1
  fi
done

# Test 9: All webhooks have failurePolicy: Fail
mutating_fail_count=$(yq eval 'select(.kind == "MutatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-mutating-webhook-configuration") | .webhooks[] | select(.failurePolicy == "Fail")' "$WORK_DIR/shoot.yaml" | grep -c "failurePolicy:" || true)
validating_fail_count=$(yq eval 'select(.kind == "ValidatingWebhookConfiguration" and .metadata.name == "ipam-capi-remote-validating-webhook-configuration") | .webhooks[] | select(.failurePolicy == "Fail")' "$WORK_DIR/shoot.yaml" | grep -c "failurePolicy:" || true)
if [ "$mutating_fail_count" = "4" ] && [ "$validating_fail_count" = "4" ]; then
  echo "PASS: All 8 webhooks have failurePolicy: Fail"
else
  echo "FAIL: Not all webhooks have failurePolicy: Fail (mutating: $mutating_fail_count/4, validating: $validating_fail_count/4)"
  failed=1
fi

# Test 10: NO webhook has the dual-deployment-operator.cc.sap/webhook-injector label
# (This label is added by DDO CR patch transformations, NOT in the vendored file)
if yq eval 'select(.kind == "MutatingWebhookConfiguration" or .kind == "ValidatingWebhookConfiguration") | select(.metadata.labels."dual-deployment-operator.cc.sap/webhook-injector")' "$WORK_DIR/shoot.yaml" | grep -q "kind:"; then
  echo "FAIL: Webhook config has dual-deployment-operator.cc.sap/webhook-injector label (should be added by DDO CR patch, not vendored file)"
  failed=1
else
  echo "PASS: NO webhook config has dual-deployment-operator.cc.sap/webhook-injector label"
fi

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All webhook parity tests PASSED ==="
  exit 0
else
  echo "=== Some webhook parity tests FAILED ==="
  exit 1
fi
