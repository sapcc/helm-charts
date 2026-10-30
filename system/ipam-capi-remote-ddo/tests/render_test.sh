#!/usr/bin/env bash
# Test: overlay tree renders cleanly and carries the required annotations
# This file is established here and extended by later tasks with additional assertions.

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

echo "=== Rendering overlay tree from $CHART_DIR ==="

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

# Test 1: seed overlay builds to exit 0
if ! kustomize build "$CHART_DIR/seed" > /tmp/seed_render.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/seed exited non-zero"
  cat /tmp/seed_render.yaml
  failed=1
else
  echo "PASS: kustomize build $CHART_DIR/seed exits 0"
fi

# Test 2: shoot overlay builds to exit 0
if ! kustomize build "$CHART_DIR/shoot" > /tmp/shoot_render.yaml 2>&1; then
  echo "FAIL: kustomize build $CHART_DIR/shoot exited non-zero"
  cat /tmp/shoot_render.yaml
  failed=1
else
  echo "PASS: kustomize build $CHART_DIR/shoot exits 0"
fi

# Test 3: seed render is empty (no documents, i.e., no 'kind:' line)
if grep -q "^kind:" /tmp/seed_render.yaml; then
  echo "FAIL: seed render should be empty at this stage (found 'kind:' line)"
  failed=1
else
  echo "PASS: seed render is empty (no documents)"
fi

# Test 4: shoot render is empty (no documents)
if grep -q "^kind:" /tmp/shoot_render.yaml; then
  echo "FAIL: shoot render should be empty at this stage (found 'kind:' line)"
  failed=1
else
  echo "PASS: shoot render is empty (no documents)"
fi

# Test 5: additions/seed/kustomization.yaml contains the origin annotation
if grep -q 'dual-deployment-operator.cc.sap/origin: additions' "$CHART_DIR/additions/seed/kustomization.yaml"; then
  echo "PASS: additions/seed/kustomization.yaml has origin annotation"
else
  echo "FAIL: additions/seed/kustomization.yaml missing origin annotation"
  failed=1
fi

# Test 6: additions/shoot/kustomization.yaml contains the origin annotation
if grep -q 'dual-deployment-operator.cc.sap/origin: additions' "$CHART_DIR/additions/shoot/kustomization.yaml"; then
  echo "PASS: additions/shoot/kustomization.yaml has origin annotation"
else
  echo "FAIL: additions/shoot/kustomization.yaml missing origin annotation"
  failed=1
fi

echo ""
if [ $failed -eq 0 ]; then
  echo "=== All tests PASSED ==="
  exit 0
else
  echo "=== Some tests FAILED ==="
  exit 1
fi
