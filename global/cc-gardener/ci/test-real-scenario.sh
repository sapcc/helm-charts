#!/bin/bash
set -e

# Test script for the real scenario described in explanation.md
# This test verifies that when cluster-specific values have:
# - values.image.repository set to a custom value (cluster override)
# - runtimeClusterValues.image explicitly set to null
# Then: runtimeClusterValues should use values.image from cluster, not defaults from chart

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing real scenario from explanation.md..."
echo "==========================================="
echo ""

# Render the chart with simulated cluster values
OUTPUT=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-real-scenario-values.testvalues" \
  --show-only templates/extension-aws.yaml 2>&1)

if [ $? -ne 0 ]; then
  echo "[FAIL] Rendering failed"
  echo "$OUTPUT"
  exit 1
fi

# Check that runtimeClusterValues.image uses the cluster-specific values.image
RUNTIME_REPO=$(echo "$OUTPUT" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
RUNTIME_TAG=$(echo "$OUTPUT" | yq '.spec.deployment.extension.runtimeClusterValues.image.tag')

EXPECTED_REPO="keppel.qa-de-1.cloud.sap/test-repo/europe-docker_pkg_dev/sap-se-gcp-k8s-delivery/releases-public/europe-docker_pkg_dev/gardener-project/releases/gardener/extensions/provider-aws"
EXPECTED_TAG="sha256:0347ea563c58fbd71463c05ff159f18cf23fb10b408476533ff766a02587565e"

echo "Expected repository: $EXPECTED_REPO"
echo "Actual repository:   $RUNTIME_REPO"
echo ""
echo "Expected tag: $EXPECTED_TAG"
echo "Actual tag:   $RUNTIME_TAG"
echo ""

if [ "$RUNTIME_REPO" = "$EXPECTED_REPO" ] && [ "$RUNTIME_TAG" = "$EXPECTED_TAG" ]; then
  echo "[PASS] runtimeClusterValues.image correctly cascaded from cluster-specific values.image"
else
  echo "[FAIL] runtimeClusterValues.image did not cascade correctly"
  exit 1
fi

# Verify that values.image also has the correct cluster-specific values
VALUES_REPO=$(echo "$OUTPUT" | yq '.spec.deployment.extension.values.image.repository')
VALUES_TAG=$(echo "$OUTPUT" | yq '.spec.deployment.extension.values.image.tag')

if [ "$VALUES_REPO" = "$EXPECTED_REPO" ] && [ "$VALUES_TAG" = "$EXPECTED_TAG" ]; then
  echo "[PASS] values.image has cluster-specific values"
else
  echo "[FAIL] values.image incorrect (repo: $VALUES_REPO, tag: $VALUES_TAG)"
  exit 1
fi

echo ""
echo "==========================================="
echo "All tests passed!"
echo ""
echo "Summary:"
echo "- Cluster values set values.image to custom repository"
echo "- Cluster values set runtimeClusterValues.image to null"
echo "- Result: runtimeClusterValues.image correctly uses cluster-specific values.image"
echo "- This prevents the chart defaults from overriding cluster-specific image configuration"
echo ""
