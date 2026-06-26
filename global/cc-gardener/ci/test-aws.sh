#!/bin/bash
set -e

# Test script for extension-aws.testvalues template
# Usage: ./ci/test-aws.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Get AWS version from values.testvalues to avoid hardcoding
AWS_VERSION=$(yq '.extensions.aws.version' "$CHART_DIR/values.yaml")

echo "Testing extension-aws.testvalues template..."
echo "==========================================="
echo ""

# Test 1: Basic rendering with default values
echo "Test 1: Basic rendering with default values"
OUTPUT1=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  --show-only templates/extension-aws.yaml)
echo "[PASS] Renders without errors"
echo ""

# Test 2: Full configuration with all features
echo "Test 2: Full configuration with all features"
OUTPUT2=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-aws-values.testvalues" \
  --show-only templates/extension-aws.yaml)
echo "[PASS] Renders with full configuration"
echo ""

# Test 2b: Configuration with admission
echo "Test 2b: Configuration with admission"
OUTPUT2B=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-aws-admission-values.testvalues" \
  --show-only templates/extension-aws.yaml)
echo "[PASS] Renders with admission configuration"
echo ""

# Test 2c: Configuration without runtimeClusterValues
echo "Test 2c: Configuration without runtimeClusterValues"
OUTPUT2C=$(helm template test "$CHART_DIR" \
  -f "$CHART_DIR/values.yaml" \
  -f "$CHART_DIR/ci/test-values.yaml" \
  -f "$CHART_DIR/ci/test-aws-no-runtimeclustervalues.testvalues" \
  --show-only templates/extension-aws.yaml)
echo "[PASS] Renders without runtimeClusterValues"
echo ""

# Test 3: Validate YAML syntax
echo "Test 3: Validate YAML syntax"
echo "$OUTPUT2" | yq '.' > /dev/null && echo "[PASS] Valid YAML syntax"
echo ""

# Test 4: Verify values.image configuration
echo "Test 4: Verify values.image configuration"
REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.image.repository')
TAG=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.image.tag')
if [ "$REPO" = "custom-aws-repo/aws-controller" ] && [ "$TAG" = "v1.67.3" ]; then
  echo "[PASS] values.image configured correctly"
else
  echo "[FAIL] values.image configuration not found (repo: $REPO, tag: $TAG)"
  exit 1
fi
echo ""

# Test 5: Verify values.images dict with alpine and pause
echo "Test 5: Verify values.images dict with alpine and pause"
ALPINE_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.images.alpine.repository')
ALPINE_TAG=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.images.alpine.tag')
PAUSE_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.images.pause.repository')
PAUSE_TAG=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.images.pause.tag')
if [ "$ALPINE_REPO" = "custom-aws-repo/alpine" ] && [ "$ALPINE_TAG" = "v3.19.0" ]; then
  echo "[PASS] alpine image configured correctly"
else
  echo "[FAIL] alpine image not correct (repo: $ALPINE_REPO, tag: $ALPINE_TAG)"
  exit 1
fi
if [ "$PAUSE_REPO" = "custom-aws-repo/pause" ] && [ "$PAUSE_TAG" = "v1.67.2" ]; then
  echo "[PASS] pause image with fallback tag"
else
  echo "[FAIL] pause image fallback not working (repo: $PAUSE_REPO, tag: $PAUSE_TAG)"
  exit 1
fi
echo ""

# Test 6: Verify image fallback to root version
echo "Test 6: Verify image fallback to root version"
TAG=$(echo "$OUTPUT1" | yq '.spec.deployment.extension.runtimeClusterValues.image.tag')
if [ "$TAG" = "$AWS_VERSION" ]; then
  echo "[PASS] Image tag falls back to root version ($AWS_VERSION)"
else
  echo "[FAIL] Image tag fallback not working (expected: $AWS_VERSION, got: $TAG)"
  exit 1
fi
echo ""

# Test 7: Verify cascading fallback for runtimeClusterValues
echo "Test 7: Verify runtimeClusterValues cascading fallback"
RUNTIME_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
if [ "$RUNTIME_REPO" = "custom-aws-repo/aws-controller" ]; then
  echo "[PASS] runtimeClusterValues repository cascaded from values.image.repository"
else
  echo "[FAIL] Cascading fallback not working (got: $RUNTIME_REPO)"
  exit 1
fi
echo ""

# Test 8: Verify OCI repository configuration
echo "Test 8: Verify OCI repository configuration"
OCI_REPO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.helm.ociRepository.repository')
OCI_TAG=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.helm.ociRepository.tag')
if [ "$OCI_REPO" = "keppel.example.com/aws-extension" ] && [ "$OCI_TAG" = "v1.67.2" ]; then
  echo "[PASS] OCI repository configured with fallback tag"
else
  echo "[FAIL] OCI repository configuration not correct (repo: $OCI_REPO, tag: $OCI_TAG)"
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
VALUES_IVO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.values.imageVectorOverwrite')
RUNTIME_IVO=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.imageVectorOverwrite')
if [ "$VALUES_IVO" != "null" ] && [ "$RUNTIME_IVO" != "null" ]; then
  echo "[PASS] imageVectorOverwrite present in values and runtimeClusterValues"
else
  echo "[FAIL] imageVectorOverwrite not found in all contexts"
  exit 1
fi
echo ""

# Test 11: Verify config.etcd.storage preserved in runtimeClusterValues
echo "Test 11: Verify config.etcd.storage preserved"
PROVISIONER=$(echo "$OUTPUT2" | yq '.spec.deployment.extension.runtimeClusterValues.config.etcd.storage.provisioner')
if [ "$PROVISIONER" = "rancher.io/local-path" ]; then
  echo "[PASS] config.etcd.storage preserved in runtimeClusterValues"
else
  echo "[FAIL] config.etcd.storage not preserved (got: $PROVISIONER)"
  exit 1
fi
echo ""

# Test 12: Verify no admission section in basic output
echo "Test 12: Verify no admission section in basic output"
ADMISSION_SECTION=$(echo "$OUTPUT1" | yq '.spec.deployment.admission')
if [ "$ADMISSION_SECTION" = "null" ]; then
  echo "[PASS] No admission section when not defined"
else
  echo "[FAIL] admission section should not be present (got: $ADMISSION_SECTION)"
  exit 1
fi
echo ""

# Test 13: Verify admission.values when defined
echo "Test 13: Verify admission.values when defined"
ADMISSION_REPO=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.values.image.repository')
ADMISSION_TAG=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.values.image.tag')
if [ "$ADMISSION_REPO" = "custom-aws-repo/aws-admission" ] && [ "$ADMISSION_TAG" = "v1.0.0" ]; then
  echo "[PASS] admission.values configured correctly"
else
  echo "[FAIL] admission.values not correct (repo: $ADMISSION_REPO, tag: $ADMISSION_TAG)"
  exit 1
fi
echo ""

# Test 14: Verify admission runtimeCluster and virtualCluster
echo "Test 14: Verify admission runtimeCluster and virtualCluster"
RUNTIME_REPO=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.runtimeCluster.helm.ociRepository.repository')
RUNTIME_TAG=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.runtimeCluster.helm.ociRepository.tag')
VIRTUAL_REPO=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.virtualCluster.helm.ociRepository.repository')
VIRTUAL_TAG=$(echo "$OUTPUT2B" | yq '.spec.deployment.admission.virtualCluster.helm.ociRepository.tag')
if [ "$RUNTIME_REPO" = "keppel.example.com/aws-admission-runtime" ] && [ "$RUNTIME_TAG" = "v1.0.1" ]; then
  echo "[PASS] admission runtimeCluster configured correctly"
else
  echo "[FAIL] admission runtimeCluster not correct (repo: $RUNTIME_REPO, tag: $RUNTIME_TAG)"
  exit 1
fi
if [ "$VIRTUAL_REPO" = "keppel.example.com/aws-admission-virtual" ] && [ "$VIRTUAL_TAG" = "v1.67.2" ]; then
  echo "[PASS] admission virtualCluster with fallback tag"
else
  echo "[FAIL] admission virtualCluster not correct (repo: $VIRTUAL_REPO, tag: $VIRTUAL_TAG)"
  exit 1
fi
echo ""

# Test 15: Verify default runtimeClusterValues when not set
echo "Test 15: Verify runtimeClusterValues with cascading from values"
RUNTIME_REPLICA=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.runtimeClusterValues.replicaCount')
RUNTIME_REPO=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.runtimeClusterValues.image.repository')
RUNTIME_TAG=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.runtimeClusterValues.image.tag')
if [ "$RUNTIME_REPLICA" = "1" ] && [ "$RUNTIME_REPO" = "custom-aws-repo/aws-controller" ] && [ "$RUNTIME_TAG" = "v1.67.3" ]; then
  echo "[PASS] runtimeClusterValues cascades from values correctly"
else
  echo "[FAIL] runtimeClusterValues not correct (replica: $RUNTIME_REPLICA, repo: $RUNTIME_REPO, tag: $RUNTIME_TAG)"
  exit 1
fi
echo ""

# Test 16: Verify config.etcd.storage present with default runtimeClusterValues
echo "Test 16: Verify config.etcd.storage present with default runtimeClusterValues"
PROVISIONER=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.runtimeClusterValues.config.etcd.storage.provisioner')
if [ "$PROVISIONER" = "rancher.io/local-path" ]; then
  echo "[PASS] config.etcd.storage present with defaults"
else
  echo "[FAIL] config.etcd.storage not present (got: $PROVISIONER)"
  exit 1
fi
echo ""

# Test 17: Verify extension.values still works without runtimeClusterValues
echo "Test 17: Verify extension.values still works without runtimeClusterValues"
EXT_REPO=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.values.image.repository')
EXT_TAG=$(echo "$OUTPUT2C" | yq '.spec.deployment.extension.values.image.tag')
if [ "$EXT_REPO" = "custom-aws-repo/aws-controller" ] && [ "$EXT_TAG" = "v1.67.3" ]; then
  echo "[PASS] extension.values configured correctly without runtimeClusterValues"
else
  echo "[FAIL] extension.values not correct (repo: $EXT_REPO, tag: $EXT_TAG)"
  exit 1
fi
echo ""

# Summary
echo "==========================================="
echo "All tests passed!"
echo ""
