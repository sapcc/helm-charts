#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname "$SCRIPT_DIR")"

# Get auditing version from values.testvalues to avoid hardcoding
AUDITING_VERSION=$(yq '.extensions.auditing.version' "$CHART_DIR/values.yaml")

echo "Testing OCI Repository Helper"
echo "=============================="
echo ""

# Test 1: ref is set (with conflicting repository/tag)
echo "Test 1: ref is set (repository and tag should be null)"
OUTPUT=$(helm template test "$CHART_DIR" -f "$CHART_DIR/values.yaml" -f "$CHART_DIR/ci/test-values.yaml" -f "$CHART_DIR/ci/test-ocirepository-ref.testvalues" --show-only templates/extension-auditing.yaml 2>&1)

# Check ref is rendered
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.ref' | grep -q "keppel.example.com/auditing:v1.0.0-custom"; then
    echo "[PASS] ref is rendered correctly"
else
    echo "[FAIL] ref is not rendered correctly"
    exit 1
fi

# Check repository is null
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.repository' | grep -q "null"; then
    echo "[PASS] repository is null"
else
    echo "[FAIL] repository is not null"
    exit 1
fi

# Check tag is null
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.tag' | grep -q "null"; then
    echo "[PASS] tag is null"
else
    echo "[FAIL] tag is not null"
    exit 1
fi

echo ""

# Test 2: only repository is set (tag comes from version fallback)
echo "Test 2: repository is set (tag should come from version, ref should be null)"
OUTPUT=$(helm template test "$CHART_DIR" -f "$CHART_DIR/values.yaml" -f "$CHART_DIR/ci/test-values.yaml" -f "$CHART_DIR/ci/test-ocirepository-repository.testvalues" --show-only templates/extension-auditing.yaml 2>&1)

# Check ref is null
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.ref' | grep -q "null"; then
    echo "[PASS] ref is null"
else
    echo "[FAIL] ref is not null"
    exit 1
fi

# Check repository is rendered
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.repository' | grep -q "keppel.example.com/auditing-custom"; then
    echo "[PASS] repository is rendered correctly"
else
    echo "[FAIL] repository is not rendered correctly"
    exit 1
fi

# Check tag comes from version fallback
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.tag' | grep -q "$AUDITING_VERSION"; then
    echo "[PASS] tag comes from version fallback ($AUDITING_VERSION)"
else
    ACTUAL_TAG=$(echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.tag')
    echo "[FAIL] tag does not come from version fallback (expected: $AUDITING_VERSION, got: $ACTUAL_TAG)"
    exit 1
fi

echo ""

# Check for blank lines
echo "Checking for blank lines in rendered output"
if echo "$OUTPUT" | grep -Pzo '\w+:\n\s*\n' > /dev/null 2>&1; then
    echo "[FAIL] Found blank lines in output"
    exit 1
else
    echo "[PASS] No blank lines found"
fi

echo ""
echo "=============================="
echo "All OCI Repository tests passed!"
