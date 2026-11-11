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
service_selector="$(yq -o=json 'select(.kind == "Service" and .metadata.name == "metal-maintenance-operator-controller-manager-telemetry-events") | .spec.selector' "$rendered")"

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
_validate_selector "Service selector"       "$service_selector"

# Now compare. Both jq calls run as checked commands; their exit status propagates.
dep_sorted="$(printf '%s\n' "$deployment_selector" | jq -S .)"
svc_sorted="$(printf '%s\n' "$service_selector"    | jq -S .)"

if [[ "$dep_sorted" != "$svc_sorted" ]]; then
  echo "FAIL: telemetry Service selector does not match the upstream Deployment selector"
  echo "  Deployment matchLabels: ${dep_sorted}"
  echo "  Service selector:       ${svc_sorted}"
  exit 1
fi

echo "PASS: telemetry Service selector matches the upstream Deployment selector"
