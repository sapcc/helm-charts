#!/bin/bash
set -e

echo "Testing Null Values Handling"
echo "============================="
echo ""

# Test 1: all ociRepository fields are null - extension.helm section should not be rendered
echo "Test 1: Null ociRepository (extension.helm section should not be rendered)"
OUTPUT=$(helm template test . -f values.testvalues -f ci/test-values.yaml -f ci/test-null-ocirepository.testvalues --show-only templates/extension-auditing.yaml 2>&1)

# Check specifically for extension.helm using yq
EXTENSION_HELM=$(echo "$OUTPUT" | yq '.spec.deployment.extension.helm' 2>/dev/null || echo "null")

if [ "$EXTENSION_HELM" != "null" ]; then
    echo "[FAIL] extension.helm section should not be rendered when all ociRepository fields are null"
    echo "Found extension.helm:"
    echo "$EXTENSION_HELM"
    exit 1
else
    echo "[PASS] extension.helm section not rendered when all ociRepository fields are null"
fi

echo ""

# Test 2: admission with all null values - sections should not be rendered
echo "Test 2: Null admission fields (runtimeCluster/virtualCluster should not be rendered)"
OUTPUT=$(helm template test . -f values.testvalues -f ci/test-values.yaml -f ci/test-null-admission.testvalues --show-only templates/extension-auditing.yaml 2>&1)

# Check specifically for admission.runtimeCluster using yq
RUNTIME_CLUSTER=$(echo "$OUTPUT" | yq '.spec.deployment.admission.runtimeCluster' 2>/dev/null || echo "null")

if [ "$RUNTIME_CLUSTER" != "null" ]; then
    echo "[FAIL] runtimeCluster should not be rendered when all ociRepository fields are null"
    echo "Found runtimeCluster:"
    echo "$RUNTIME_CLUSTER"
    exit 1
else
    echo "[PASS] runtimeCluster not rendered when all ociRepository fields are null"
fi

# Check specifically for admission.virtualCluster using yq
VIRTUAL_CLUSTER=$(echo "$OUTPUT" | yq '.spec.deployment.admission.virtualCluster' 2>/dev/null || echo "null")

if [ "$VIRTUAL_CLUSTER" != "null" ]; then
    echo "[FAIL] virtualCluster should not be rendered when all ociRepository fields are null"
    echo "Found virtualCluster:"
    echo "$VIRTUAL_CLUSTER"
    exit 1
else
    echo "[PASS] virtualCluster not rendered when all ociRepository fields are null"
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
echo "============================="
echo "All null values tests passed!"
