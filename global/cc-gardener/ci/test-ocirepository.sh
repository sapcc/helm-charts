#!/bin/bash
set -e

echo "Testing OCI Repository Helper"
echo "=============================="
echo ""

# Test 1: ref is set (with conflicting repository/tag)
echo "Test 1: ref is set (repository and tag should be null)"
OUTPUT=$(helm template test . -f values.yaml -f ci/test-values.yaml -f ci/test-ocirepository-ref.yaml --show-only templates/extension-auditing.yaml 2>&1)

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
OUTPUT=$(helm template test . -f values.yaml -f ci/test-values.yaml -f ci/test-ocirepository-repository.yaml --show-only templates/extension-auditing.yaml 2>&1)

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
if echo "$OUTPUT" | yq '.spec.deployment.extension.helm.ociRepository.tag' | grep -q "v0.3.0"; then
    echo "[PASS] tag comes from version fallback (v0.3.0)"
else
    echo "[FAIL] tag does not come from version fallback"
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
