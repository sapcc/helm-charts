#!/bin/bash
set -e

# Test script for extension-auditing.yaml template
# Usage: ./ci/test-auditing.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

echo "Testing extension-auditing.yaml template..."
echo "==========================================="
echo ""

# Test 1: Basic rendering with default values
echo "Test 1: Basic rendering with default values"
OUTPUT1=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  --show-only templates/extension-auditing.yaml)
echo "[PASS] Renders without errors"
echo ""

# Test 2: Full configuration with all features
echo "Test 2: Full configuration with all features"
OUTPUT2=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-auditing-values.yaml" \
  --show-only templates/extension-auditing.yaml)
echo "[PASS] Renders with full configuration"
echo ""

# Test 3: Validate YAML syntax
echo "Test 3: Validate YAML syntax"
echo "$OUTPUT2" | yq '.' > /dev/null && echo "[PASS] Valid YAML syntax"
echo ""

# Test 4: Verify admission.values are present
echo "Test 4: Verify admission.values configuration"
if echo "$OUTPUT2" | yq '.spec.deployment.admission.values.customAdmissionValue' | grep -q "test123"; then
  echo "[PASS] admission.values passed through correctly"
else
  echo "[FAIL] admission.values not found"
  exit 1
fi
echo ""

# Test 5: Verify image fallback logic
echo "Test 5: Verify image fallback to root version"
TAG=$(echo "$OUTPUT1" | yq '.spec.deployment.extension.helm.ociRepository.tag')
if [ "$TAG" = "v0.2.0" ]; then
  echo "[PASS] Image tag falls back to root version"
else
  echo "[FAIL] Image tag fallback not working (got: $TAG)"
  exit 1
fi
echo ""

# Test 6: Verify custom image configuration
echo "Test 6: Verify custom image configuration"
REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.admission.values.image.repository')
TAG=$(echo "$OUTPUT2" | yq '.spec.deployment.admission.values.image.tag')
if [ "$REPO" = "custom-admission-repo/auditing-admission" ] && [ "$TAG" = "v0.3.0-custom" ]; then
  echo "[PASS] Custom admission image configured correctly"
else
  echo "[FAIL] Custom image configuration not found (repo: $REPO, tag: $TAG)"
  exit 1
fi
echo ""

# Test 7: Verify cascading fallback for runtimeClusterValues
echo "Test 7: Verify runtimeClusterValues cascading fallback"
RUNTIME_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
if [ "$RUNTIME_REPO" = "custom-extension-repo/auditing-controller" ]; then
  echo "[PASS] runtimeClusterValues repository cascaded from values.image.repository"
else
  echo "[FAIL] Cascading fallback not working (got: $RUNTIME_REPO)"
  exit 1
fi
echo ""

# Test 8: Verify OCI repository configuration
echo "Test 8: Verify OCI repository configuration"
OCI_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.admission.runtimeCluster.helm.ociRepository.repository')
if [ "$OCI_REPO" = "keppel.example.com/auditing-admission-runtime" ]; then
  echo "[PASS] OCI repository configured correctly"
else
  echo "[FAIL] OCI repository configuration not found (got: $OCI_REPO)"
  exit 1
fi
echo ""

# Test 9: Verify no extra blank lines
echo "Test 9: Verify no extra blank lines"
# Check for blank lines after any key (pattern: "key:\n  \n")
if echo "$OUTPUT1" | grep -Pzo "(?s)\w+:\n\s*\n" > /dev/null 2>&1; then
  echo "[FAIL] Found blank lines after keys in basic output"
  exit 1
fi
if echo "$OUTPUT2" | grep -Pzo "(?s)\w+:\n\s*\n" > /dev/null 2>&1; then
  echo "[FAIL] Found blank lines after keys in full output"
  exit 1
fi
echo "[PASS] No extra blank lines"
echo ""

# Test 10: Verify imageVectorOverwrite in multiple contexts
echo "Test 10: Verify imageVectorOverwrite support"
ADMISSION_IVO=$(echo "$OUTPUT2" | yq '.spec.deployment.admission.values.imageVectorOverwrite')
VALUES_IVO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.imageVectorOverwrite')
RUNTIME_IVO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.imageVectorOverwrite')
if [ "$ADMISSION_IVO" != "null" ] && [ "$VALUES_IVO" != "null" ] && [ "$RUNTIME_IVO" != "null" ]; then
  echo "[PASS] imageVectorOverwrite present in admission.values, values, and runtimeClusterValues"
else
  echo "[FAIL] imageVectorOverwrite not found in all contexts"
  exit 1
fi
echo ""

# Summary
echo "==========================================="
echo "All tests passed!"
echo ""
