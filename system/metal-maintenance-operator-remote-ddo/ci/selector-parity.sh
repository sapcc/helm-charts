#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template metal-maintenance-operator-remote "$chart_dir" --set mode=seed \
  --set mmo-core.manager.enabled=true >"$rendered"

# Extract selectors into variables using CHECKED commands (not process substitution
# where exit codes are discarded). yq failures propagate immediately via set -euo pipefail.
deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "metal-maintenance-operator-controller-manager") | .spec.selector.matchLabels' "$rendered")"

# The seed render contains TWO telemetry Services with the same name:
#   1. upstream-origin  — from the subchart (no origin annotation)
#   2. additions-origin — from templates/telemetry-service.yaml
#      (annotation: dual-deployment-operator.cc.sap/origin: additions)
# Both must have a selector that matches the Deployment's matchLabels; validating only
# one would miss drift on the other. Extract all matching Service selectors as a JSON array.
service_selectors_json="$(yq -o=json '[select(.kind == "Service" and .metadata.name == "metal-maintenance-operator-controller-manager-telemetry-events") | .spec.selector]' "$rendered" | jq -s 'add')"

# Validate each extraction is a non-empty JSON object with at least one key.
# Reject: empty string, "null", "{}", "[]", or any value jq cannot parse as an object.
_validate_selector() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    echo "FAIL: ${name} extracted as empty string — resource not found in render" >&2
    exit 1
  fi
  local key_count
  key_count="$(printf '%s\n' "$value" | jq 'if type == "object" then keys | length else -1 end')"
  if [[ "$key_count" -le 0 ]]; then
    echo "FAIL: ${name} is not a non-empty JSON object (got: ${value})" >&2
    exit 1
  fi
}

_validate_selector "Deployment matchLabels" "$deployment_selector"

# Ensure we found at least 2 telemetry Services (upstream + additions).
svc_count="$(printf '%s\n' "$service_selectors_json" | jq 'length')"
if [[ "$svc_count" -lt 2 ]]; then
  echo "FAIL: expected at least 2 telemetry Services in seed render (upstream + additions), found ${svc_count}" >&2
  exit 1
fi

# Validate each Service selector and compare it to the Deployment matchLabels.
dep_sorted="$(printf '%s\n' "$deployment_selector" | jq -S .)"
for i in $(seq 0 $((svc_count - 1))); do
  svc_selector="$(printf '%s\n' "$service_selectors_json" | jq ".[$i]")"
  _validate_selector "Service selector [${i}]" "$svc_selector"
  svc_sorted="$(printf '%s\n' "$svc_selector" | jq -S .)"
  if [[ "$dep_sorted" != "$svc_sorted" ]]; then
    echo "FAIL: telemetry Service selector [${i}] does not match the upstream Deployment selector"
    echo "  Deployment matchLabels:   ${dep_sorted}"
    echo "  Service selector [${i}]:  ${svc_sorted}"
    exit 1
  fi
done

echo "PASS: telemetry Service selector matches the upstream Deployment selector (checked ${svc_count} Services)"
