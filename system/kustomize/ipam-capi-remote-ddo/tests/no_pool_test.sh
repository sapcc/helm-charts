#!/usr/bin/env bash
# Test: shoot overlay contains no GlobalInClusterIPPool objects (a-qa-de-200 has none)
# Also validates that pools.example.yaml has correct structure (single spec:, not duplicate bug)

set -euo pipefail

# Resolve chart directory relative to this script, so it runs from any cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$TESTS_DIR"

# Ensure kustomize is available
if ! command -v kustomize &> /dev/null; then
  echo "FAIL: kustomize not found in PATH"
  exit 1
fi

echo "=== Running no_pool_test ==="

# Helper: run assertion and print result
assert() {
  local name="$1"
  local cmd="$2"
  
  if eval "$cmd" > /dev/null 2>&1; then
    echo "PASS: $name"
    return 0
  else
    echo "FAIL: $name"
    return 1
  fi
}

# Track overall test result
failed=0

# Test 1: shoot overlay builds to exit 0
if ! kustomize build "$CHART_DIR/shoot" > /tmp/shoot_render.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/shoot exited non-zero"
  cat /tmp/shoot_render.yaml
  failed=1
else
  echo "PASS: kustomize build $CHART_DIR/shoot exits 0"
fi

# Test 2: shoot render contains ZERO GlobalInClusterIPPool objects (a-qa-de-200 has none)
pool_count="$(grep -c '^kind: GlobalInClusterIPPool$' /tmp/shoot_render.yaml || true)"
if [ "$pool_count" -ne 0 ]; then
  echo "FAIL: shoot render should contain 0 GlobalInClusterIPPool objects (found $pool_count)"
  failed=1
else
  echo "PASS: shoot render contains 0 GlobalInClusterIPPool objects"
fi

# Test 3: pools.example.yaml exists
if [ ! -f "$CHART_DIR/additions/shoot/pools.example.yaml" ]; then
  echo "FAIL: pools.example.yaml does not exist"
  failed=1
else
  echo "PASS: pools.example.yaml exists"
  
  # Test 4: pools.example.yaml is valid YAML
  if ! python3 -c "import yaml; yaml.safe_load(open('$CHART_DIR/additions/shoot/pools.example.yaml'))" 2>&1; then
    echo "FAIL: pools.example.yaml is not valid YAML"
    failed=1
  else
    echo "PASS: pools.example.yaml is valid YAML"
    
    # Test 5: pools.example.yaml has exactly ONE 'spec:' key (regression test for duplicate bug)
    spec_count="$(grep -c '^spec:' "$CHART_DIR/additions/shoot/pools.example.yaml" || true)"
    if [ "$spec_count" -ne 1 ]; then
      echo "FAIL: pools.example.yaml should have exactly 1 'spec:' key (found $spec_count) - regression on duplicate spec bug"
      failed=1
    else
      echo "PASS: pools.example.yaml has exactly 1 'spec:' key (no duplicate bug)"
    fi
    
    # Test 6: pools.example.yaml has kind GlobalInClusterIPPool
    if ! grep -q '^kind: GlobalInClusterIPPool$' "$CHART_DIR/additions/shoot/pools.example.yaml"; then
      echo "FAIL: pools.example.yaml should have kind: GlobalInClusterIPPool"
      failed=1
    else
      echo "PASS: pools.example.yaml has kind: GlobalInClusterIPPool"
    fi
    
    # Test 7: pools.example.yaml has namespace metal-servers
    if ! grep -q 'namespace: metal-servers' "$CHART_DIR/additions/shoot/pools.example.yaml"; then
      echo "FAIL: pools.example.yaml should have namespace: metal-servers"
      failed=1
    else
      echo "PASS: pools.example.yaml has namespace: metal-servers"
    fi
    
    # Test 8: pools.example.yaml has apiVersion ipam.cluster.x-k8s.io/v1alpha2
    if ! grep -q 'apiVersion: ipam.cluster.x-k8s.io/v1alpha2' "$CHART_DIR/additions/shoot/pools.example.yaml"; then
      echo "FAIL: pools.example.yaml should have apiVersion: ipam.cluster.x-k8s.io/v1alpha2"
      failed=1
    else
      echo "PASS: pools.example.yaml has apiVersion: ipam.cluster.x-k8s.io/v1alpha2"
    fi
  fi
fi

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All no_pool tests PASSED ==="
  exit 0
else
  echo "=== Some no_pool tests FAILED ==="
  exit 1
fi
