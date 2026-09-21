#!/bin/bash
set -euo pipefail

# DDO Integration Test Suite — 12 RED phase test cases (all should FAIL)
# Coverage: Q1 (subchart disable), Q2 (values structure), Q3 (CR template), Q4 (validation)

CHART_DIR="${CHART_DIR:-.}"
HELM_BIN="${HELM_BIN:-helm}"

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper: assert file exists
assert_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}FAIL${NC}: File does not exist: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}PASS${NC}: File exists: $file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper: assert key exists in YAML
assert_yaml_key() {
    local file="$1"
    local key="$2"
    if ! grep -q "^${key}:" "$file"; then
        echo -e "${RED}FAIL${NC}: YAML key '$key' not found in $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}PASS${NC}: YAML key '$key' found in $file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper: assert subchart condition in Chart.yaml
assert_subchart_condition() {
    local file="$1"
    if ! grep -q "condition: metal-operator.enabled" "$file"; then
        echo -e "${RED}FAIL${NC}: Subchart condition 'metal-operator.enabled' not found in $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}PASS${NC}: Subchart condition 'metal-operator.enabled' found in $file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper: assert helm lint passes
assert_helm_lint() {
    local chart_path="$1"
    if ! $HELM_BIN lint "$chart_path" > /dev/null 2>&1; then
        echo -e "${RED}FAIL${NC}: helm lint failed for $chart_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}PASS${NC}: helm lint passed for $chart_path"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper: assert template renders without error
assert_template_renders() {
    local chart_path="$1"
    local values_file="${2:-}"
    if [ -n "$values_file" ]; then
        if ! $HELM_BIN template test "$chart_path" -f "$values_file" > /dev/null 2>&1; then
            echo -e "${RED}FAIL${NC}: helm template failed for $chart_path with values $values_file"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if ! $HELM_BIN template test "$chart_path" > /dev/null 2>&1; then
            echo -e "${RED}FAIL${NC}: helm template failed for $chart_path"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
    echo -e "${GREEN}PASS${NC}: helm template rendered successfully for $chart_path"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

# Helper: assert key value in YAML
assert_yaml_value() {
    local file="$1"
    local key="$2"
    local expected_value="$3"
    local actual_value
    actual_value=$(grep "^${key}:" "$file" | head -1 | sed "s/^${key}: *//" || echo "")
    if [ "$actual_value" != "$expected_value" ]; then
        echo -e "${RED}FAIL${NC}: YAML key '$key' in $file has value '$actual_value', expected '$expected_value'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}PASS${NC}: YAML key '$key' in $file has correct value '$expected_value'"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
}

echo "========================================"
echo "DDO Integration Test Suite (RED Phase)"
echo "========================================"
echo ""

# Q1: Subchart Disable Tests (3 tests)
echo -e "${YELLOW}=== Q1: Subchart Disable (metal-operator.enabled condition) ===${NC}"
TESTS_RUN=$((TESTS_RUN + 1))
assert_file_exists "$CHART_DIR/Chart.yaml" || true
TESTS_RUN=$((TESTS_RUN + 1))
assert_subchart_condition "$CHART_DIR/Chart.yaml" || true
TESTS_RUN=$((TESTS_RUN + 1))
assert_yaml_value "$CHART_DIR/values.yaml" "metal-operator.enabled" "false" || true
echo ""

# Q2: Values Structure Tests (3 tests)
echo -e "${YELLOW}=== Q2: Values Structure (seed/shoot overrides) ===${NC}"
TESTS_RUN=$((TESTS_RUN + 1))
assert_file_exists "$CHART_DIR/values-seed-overrides.yaml" || true
TESTS_RUN=$((TESTS_RUN + 1))
assert_file_exists "$CHART_DIR/values-shoot-overrides.yaml" || true
TESTS_RUN=$((TESTS_RUN + 1))
assert_yaml_key "$CHART_DIR/values.yaml" "mode" || true
echo ""

# Q3: CR Template Injection Tests (3 tests)
echo -e "${YELLOW}=== Q3: CR Template Injection (.Values.mode reference) ===${NC}"
TESTS_RUN=$((TESTS_RUN + 1))
assert_file_exists "$CHART_DIR/templates/dualdeploymentoperator-cr.yaml" || true
TESTS_RUN=$((TESTS_RUN + 1))
if [ -f "$CHART_DIR/templates/dualdeploymentoperator-cr.yaml" ]; then
    if grep -q "\.Values\.mode" "$CHART_DIR/templates/dualdeploymentoperator-cr.yaml"; then
        echo -e "${GREEN}PASS${NC}: .Values.mode reference found in dualdeploymentoperator-cr.yaml"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}: .Values.mode reference not found in dualdeploymentoperator-cr.yaml"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "${RED}FAIL${NC}: dualdeploymentoperator-cr.yaml does not exist"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
assert_template_renders "$CHART_DIR" "$CHART_DIR/values.yaml" || true
echo ""

# Q4: Validation Tests (3 tests)
echo -e "${YELLOW}=== Q4: Validation (schema, linting, manifests) ===${NC}"
TESTS_RUN=$((TESTS_RUN + 1))
assert_file_exists "$CHART_DIR/values.schema.json" || true
TESTS_RUN=$((TESTS_RUN + 1))
assert_helm_lint "$CHART_DIR" || true
TESTS_RUN=$((TESTS_RUN + 1))
# Verify all required fields are present in rendered manifest
if $HELM_BIN template test "$CHART_DIR" 2>/dev/null | grep -q "kind: DualDeploymentOperator"; then
    echo -e "${GREEN}PASS${NC}: DualDeploymentOperator kind present in rendered manifests"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC}: DualDeploymentOperator kind not found in rendered manifests"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total Tests Run: $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "========================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests PASSED!${NC}"
    exit 0
else
    echo -e "${RED}$TESTS_FAILED test(s) FAILED${NC}"
    exit 1
fi
