#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template metal-maintenance-operator-remote "$chart_dir" --set mode=seed \
  --set mmo-core.manager.enabled=true >"$rendered"

deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "metal-maintenance-operator-controller-manager") | .spec.selector.matchLabels' "$rendered")"
service_selector="$(yq -o=json 'select(.kind == "Service" and .metadata.name == "metal-maintenance-operator-controller-manager-telemetry-events") | .spec.selector' "$rendered")"

if [[ -z "$deployment_selector" || -z "$service_selector" ]] || ! diff -u \
  <(printf '%s\n' "$deployment_selector" | jq -S .) \
  <(printf '%s\n' "$service_selector" | jq -S .); then
  echo "FAIL: telemetry Service selector does not match the upstream Deployment selector"
  exit 1
fi

echo "PASS: telemetry Service selector matches the upstream Deployment selector"
