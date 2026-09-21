#!/bin/bash
#
# RED-Phase Test: Per-Shoot Configuration Injection (Seed Mode)
#
# Purpose: Verify that seed-mode DualDeploymentOperator CR properly injects
# per-shoot configuration into metal-operator-remote-v2 chart via seedValues.
#
# Expected behavior (FAILING):
#   1. Chart renders without error
#   2. Injection points (seedValues placeholders) remain UNFILLED in output
#   3. Test assertion FAILS (confirms feature not yet implemented)
#
# Test framework: Manual helm template + yq parsing (Option B)
#

set -e

CHART_DIR="/Users/D065300/IdeaProjects/sapcc/helm-charts/system/metal-operator-remote-v2"
TEST_DIR="$CHART_DIR/tests"

echo "=========================================="
echo "RED-Phase Test: Per-Shoot Config Injection"
echo "Started: $(date)"
echo "=========================================="

# Define DualDeploymentOperator CR (seed-mode override values)
cat <<'DDO_EOF'
DDO_CR_VALUES=$(cat <<'SEEDVALUES'
seedValues: |
  remote:
    host: "seed-webhook.garden.svc.cluster.local"
    port: 9443
    caSecret:
      name: "seed-ca"
      namespace: "garden"
  gardener:
    namespace: "garden"
    certSecret:
      name: "seed-cert"
      namespace: "garden"
SEEDVALUES
echo "DEBUG: DDO_CR_VALUES defined"
DDO_EOF

# Write seedValues to temp file (replacing process substitution)
echo "DEBUG: Creating temp file for seedValues..."
TEMP_VALUES=$(mktemp)
echo "DEBUG: Temp file path: $TEMP_VALUES"
trap "rm -f $TEMP_VALUES" EXIT

cat > "$TEMP_VALUES" << 'SEEDVALUES'
seedValues: |
  remote:
    host: "seed-webhook.garden.svc.cluster.local"
    port: 9443
    caSecret:
      name: "seed-ca"
      namespace: "garden"
  gardener:
    namespace: "garden"
    certSecret:
      name: "seed-cert"
      namespace: "garden"
SEEDVALUES

echo "DEBUG: seedValues written to temp file"
echo "DEBUG: Temp file contents:"
cat "$TEMP_VALUES"
echo "DEBUG: ---"

# Change to chart directory for helm template execution
cd "$CHART_DIR"
echo "DEBUG: Changed to chart directory: $(pwd)"

# Invoke helm template with seedValues injection
echo "DEBUG: Invoking helm template..."
echo "DEBUG: Command: helm template metal-operator-remote-v2 . --values \"$TEMP_VALUES\""

HELM_STDOUT=$(mktemp)
HELM_STDERR=$(mktemp)
HELM_EXIT_CODE=0

helm template metal-operator-remote-v2 . --values "$TEMP_VALUES" \
  > "$HELM_STDOUT" 2> "$HELM_STDERR" \
  || HELM_EXIT_CODE=$?

trap "rm -f $TEMP_VALUES $HELM_STDOUT $HELM_STDERR" EXIT

echo "DEBUG: Helm exit code: $HELM_EXIT_CODE"
echo "DEBUG: Helm stdout size: $(wc -c < "$HELM_STDOUT") bytes"
echo "DEBUG: Helm stderr size: $(wc -c < "$HELM_STDERR") bytes"

if [ $HELM_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Helm template failed!"
  echo "STDERR:"
  cat "$HELM_STDERR"
  exit 1
fi

if [ ! -s "$HELM_STDOUT" ]; then
  echo "ERROR: Helm template produced no output!"
  exit 1
fi

echo "DEBUG: Helm template succeeded. Output size: $(wc -c < "$HELM_STDOUT") bytes"
echo "DEBUG: First 500 chars of helm output:"
head -c 500 "$HELM_STDOUT"
echo ""
echo "DEBUG: ---"

# Parse rendered manifests to find Deployment resources
echo "DEBUG: Parsing helm output for Deployment resources..."
DEPLOYMENT_COUNT=$(grep -c "^kind: Deployment" "$HELM_STDOUT" || echo 0)
echo "DEBUG: Found $DEPLOYMENT_COUNT Deployment resource(s)"

if [ "$DEPLOYMENT_COUNT" -eq 0 ]; then
  echo "ERROR: No Deployment resources found in helm output!"
  echo "Full helm output:"
  cat "$HELM_STDOUT"
  exit 1
fi

# Extract first Deployment and check for seedValues injection
echo "DEBUG: Extracting first Deployment resource..."
FIRST_DEPLOYMENT=$(awk '/^---/,/^kind: Deployment/ {next} /^kind: Deployment/,/^---/ {print}' "$HELM_STDOUT" | head -100)

echo "DEBUG: First 300 chars of Deployment:"
echo "$FIRST_DEPLOYMENT" | head -c 300
echo ""
echo "DEBUG: ---"

# TEST ASSERTION: Verify seedValues injection
echo "DEBUG: Checking for seedValues injection in Deployment spec..."

if echo "$FIRST_DEPLOYMENT" | grep -q "seed-webhook.garden.svc.cluster.local"; then
  echo "PASS: seedValues injection detected (remote.host present)"
  exit 0
else
  echo "FAIL: seedValues injection NOT detected (remote.host missing)"
  echo "Expected: seed-webhook.garden.svc.cluster.local in rendered manifest"
  echo "Full Deployment spec (first 1000 chars):"
  echo "$FIRST_DEPLOYMENT" | head -c 1000
  exit 1
fi
