#!/usr/bin/env bash
# Checks that no apiserver audit policy shipped from this repo writes credentials into the
# audit log: Secret bodies, issued service account tokens, TokenReview requests, shoot
# kubeconfigs and similar (see SENSITIVE in audit-policy-check.py).
#
# Policies checked:
#   - cc-runtime-cluster: the policy file embedded in the KubeadmControlPlane
#   - cc-gardener: the shoot policies in managedresources/configmap-auditing-policy*.yaml
#   - cc-gardener: the default gardenPolicy and virtualPolicy in values.yaml
#   - optionally, every gardenPolicy/virtualPolicy override in a values checkout
#
# Usage: ci/audit-policy-conformance.sh [VALUES_DIR]
# Requires helm, yq v4 and python3. Exits non-zero if any policy fails or cannot be read.

set -euo pipefail

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_CHART="$(cd "$CHART_DIR/../.." && pwd)/system/cc-runtime-cluster"
VALUES_DIR="${1:-}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
POLICIES=()
FAIL=0

# add_policy <label> <file>: queue the audit Policy in <file> for the check.
add_policy() {
  local json="$TMP/policy-${#POLICIES[@]}.json"
  if [ -s "$2" ] && yq -e '.kind == "Policy"' "$2" >/dev/null 2>&1 && yq -o=json '.' "$2" > "$json"; then
    POLICIES+=("$1=$json")
  else
    echo "ERROR [$1]: could not extract an audit Policy"
    FAIL=1
  fi
}

# Runtime clusters: the policy is an ignition file in the KubeadmControlPlane.
helm template "$RUNTIME_CHART" -f "$RUNTIME_CHART/ci/test-values.yaml" \
    --show-only templates/kubeadmcontrolplane.yaml 2>/dev/null \
  | yq eval-all '[select(.kind == "KubeadmControlPlane")] | .[0].spec.kubeadmConfigSpec.files[]
      | select(.path == "/etc/kubernetes/audit-policy.yaml") | .content' - > "$TMP/runtime.yaml" || true
add_policy "cc-runtime-cluster/kubeadmcontrolplane" "$TMP/runtime.yaml"

# Shoots: plain ConfigMaps inside a single {{ if }} ... {{ end }} guard, which is dropped here.
# Any other template logic would be dropped too, so refuse to guess.
for f in "$CHART_DIR"/managedresources/configmap-auditing-policy*.yaml; do
  name="$(basename "$f" .yaml)"
  if [ "$(grep -c '{{' "$f")" -gt 2 ]; then
    echo "ERROR [cc-gardener/managedresources/$name]: template logic besides the if/end guard, extend this check to render it"
    FAIL=1
    continue
  fi
  sed '/{{/d' "$f" | yq '.data.policy' - > "$TMP/$name.yaml" 2>/dev/null || true
  add_policy "cc-gardener/managedresources/$name" "$TMP/$name.yaml"
done

# Garden and virtual garden apiservers: chart defaults.
for key in gardenPolicy virtualPolicy; do
  yq ".extensions.auditing.$key" "$CHART_DIR/values.yaml" > "$TMP/default-$key.yaml" 2>/dev/null || true
  add_policy "cc-gardener/values.yaml:$key" "$TMP/default-$key.yaml"
done

# Overrides from a values checkout, if one is given.
if [ -n "$VALUES_DIR" ]; then
  while IFS= read -r f; do
    for key in gardenPolicy virtualPolicy; do
      yq "[.. | select(has(\"$key\")) | .$key] | .[0]" "$f" > "$TMP/override.yaml" 2>/dev/null || continue
      grep -q 'kind: Policy' "$TMP/override.yaml" || continue
      add_policy "${f#"$VALUES_DIR"/}:$key" "$TMP/override.yaml"
    done
  done < <(grep -rlE 'gardenPolicy|virtualPolicy' "$VALUES_DIR" --include='*.yaml')
fi

if [ "${#POLICIES[@]}" -gt 0 ]; then
  python3 "$CHART_DIR/ci/audit-policy-check.py" "${POLICIES[@]}" || FAIL=1
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "AUDIT POLICY CONFORMANCE: FAILED"
  exit 1
fi
echo "AUDIT POLICY CONFORMANCE: PASSED"
