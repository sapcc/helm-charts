#!/bin/bash
set -e

# Test script for image cascading fallback issue from explanation.md
# Usage: ./ci/test-image-cascade.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing image cascading fallback (explanation.md issue)..."
echo "==========================================="
echo ""

# Test case matching explanation.md:
# - values.image.repository is set (custom cluster value)
# - values.image.tag is set (custom cluster value)
# - runtimeClusterValues.image exists but is empty dict {}
# Expected: runtimeClusterValues should use values.image.repository from cluster
# Current bug: runtimeClusterValues uses default repository from chart

echo "Test 1: runtimeClusterValues image cascades from cluster values.image.repository"
OUTPUT=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  --set extensions.aws.enabled=true \
  --set extensions.aws.version=v1.68.3 \
  --set extensions.aws.values.image.repository="keppel.qa-de-1.cloud.sap/test-repo/europe-docker_pkg_dev/sap-se-gcp-k8s-delivery/releases-public/europe-docker_pkg_dev/gardener-project/releases/gardener/extensions/provider-aws" \
  --set extensions.aws.values.image.tag="sha256:0347ea563c58fbd71463c05ff159f18cf23fb10b408476533ff766a02587565e" \
  --set extensions.aws.runtimeClusterValues.image.repository="" \
  --set extensions.aws.runtimeClusterValues.image.tag="sha256:0347ea563c58fbd71463c05ff159f18cf23fb10b408476533ff766a02587565e" \
  --set extensions.aws.helm.ociRepository.ref="keppel.qa-de-1.cloud.sap/test-repo/europe-docker_pkg_dev/sap-se-gcp-k8s-delivery/releases-public/europe-docker-pkg-dev/gardener-project/releases/charts/gardener/extensions/provider-aws@sha256:04f261c72c0051a7a75a7b9ad0ff86923d992eca639a90754e6813640663d251" \
  --show-only templates/extension-aws.yaml 2>&1)

if [ $? -ne 0 ]; then
  echo "[FAIL] Rendering failed"
  echo "$OUTPUT"
  exit 1
fi

RUNTIME_REPO=$(echo "$OUTPUT" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
EXPECTED_REPO="keppel.qa-de-1.cloud.sap/test-repo/europe-docker_pkg_dev/sap-se-gcp-k8s-delivery/releases-public/europe-docker_pkg_dev/gardener-project/releases/gardener/extensions/provider-aws"

echo "Expected repository: $EXPECTED_REPO"
echo "Actual repository:   $RUNTIME_REPO"
echo ""

if [ "$RUNTIME_REPO" = "$EXPECTED_REPO" ]; then
  echo "[PASS] runtimeClusterValues.image.repository cascaded from values.image.repository"
else
  echo "[FAIL] runtimeClusterValues.image.repository should cascade from cluster values.image.repository"
  echo "       but got: $RUNTIME_REPO"
  exit 1
fi
echo ""

# Test 2: When runtimeClusterValues.image is explicitly null (cluster override)
echo "Test 2: Null runtimeClusterValues.image should cascade from parent values"

OUTPUT2=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-image-cascade-values.testvalues" \
  --show-only templates/extension-aws.yaml 2>&1)

RUNTIME_REPO2=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
if [ "$RUNTIME_REPO2" = "custom-cluster-repo/aws-provider" ]; then
  echo "[PASS] Empty repository cascaded from parent values"
else
  echo "[FAIL] Expected: custom-cluster-repo/aws-provider, got: $RUNTIME_REPO2"
  exit 1
fi
echo ""

echo "==========================================="
echo "All tests passed!"
echo ""
