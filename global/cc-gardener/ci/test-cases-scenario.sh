#!/bin/bash
set -e

# Test script for the scenario described in cases.md
# This tests the case where:
# - Cluster values set values.image.repository to custom repo
# - Cluster values do NOT set runtimeClusterValues.image
# - Chart defaults have runtimeClusterValues.image.repository set
# Expected: runtimeClusterValues should cascade from values.image, not use chart defaults

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing cases.md scenario..."
echo "==========================================="
echo ""

# Render the chart with values that simulate cases.md
OUTPUT=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-cases-md-scenario.testvalues" \
  --show-only templates/extension-aws.yaml 2>&1)

if [ $? -ne 0 ]; then
  echo "[FAIL] Rendering failed"
  echo "$OUTPUT"
  exit 1
fi

# Check values.image uses cluster-specific repository
VALUES_REPO=$(echo "$OUTPUT" | yq '.spec.deployment.extension.values.image.repository')
EXPECTED_VALUES_REPO="keppel.qa-de-1.cloud.sap/test-repo/europe-docker_pkg_dev/sap-se-gcp-k8s-delivery/releases-public/europe-docker_pkg_dev/gardener-project/releases/gardener/extensions/provider-aws"

echo "Test 1: values.image.repository uses cluster-specific repository"
echo "Expected: $EXPECTED_VALUES_REPO"
echo "Actual:   $VALUES_REPO"
echo ""

if [ "$VALUES_REPO" != "$EXPECTED_VALUES_REPO" ]; then
  echo "[FAIL] values.image.repository is incorrect"
  exit 1
fi
echo "[PASS] values.image.repository is correct"
echo ""

# Check runtimeClusterValues.image cascades from values.image
RUNTIME_REPO=$(echo "$OUTPUT" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
RUNTIME_TAG=$(echo "$OUTPUT" | yq '.spec.deployment.extension.runtimeClusterValues.image.tag')
EXPECTED_RUNTIME_REPO="$EXPECTED_VALUES_REPO"
EXPECTED_RUNTIME_TAG="sha256:0347ea563c58fbd71463c05ff159f18cf23fb10b408476533ff766a02587565e"

# This is the key test - it should NOT be the chart default!
CHART_DEFAULT_REPO=$(yq '.extensions.aws.runtimeClusterValues.image.repository' "$CHART_DIR/values.yaml")

echo "Test 2: runtimeClusterValues.image cascades from values.image"
echo "Expected repo: $EXPECTED_RUNTIME_REPO"
echo "Actual repo:   $RUNTIME_REPO"
echo "Chart default: $CHART_DEFAULT_REPO"
echo ""
echo "Expected tag: $EXPECTED_RUNTIME_TAG"
echo "Actual tag:   $RUNTIME_TAG"
echo ""

if [ "$RUNTIME_REPO" = "$CHART_DEFAULT_REPO" ]; then
  echo "[FAIL] runtimeClusterValues is using chart defaults instead of cascading from values!"
  echo "This is the bug described in explanation.md"
  exit 1
fi

if [ "$RUNTIME_REPO" != "$EXPECTED_RUNTIME_REPO" ]; then
  echo "[FAIL] runtimeClusterValues.image.repository did not cascade correctly"
  exit 1
fi

if [ "$RUNTIME_TAG" != "$EXPECTED_RUNTIME_TAG" ]; then
  echo "[FAIL] runtimeClusterValues.image.tag did not cascade correctly"
  exit 1
fi

echo "[PASS] runtimeClusterValues.image correctly cascaded from values.image"
echo "[PASS] Did NOT use chart defaults (which would be wrong)"
echo ""

echo "==========================================="
echo "All tests passed!"
echo ""
echo "Summary:"
echo "- Cluster values set values.image to custom repository"
echo "- Cluster values did NOT set runtimeClusterValues.image"
echo "- Chart has runtimeClusterValues.image.repository in defaults"
echo "- Result: runtimeClusterValues correctly cascaded from values.image"
echo "- Did NOT incorrectly use chart defaults after Helm merge"
echo ""
