#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template boot-operator-remote "$chart_dir" --set mode=seed \
  --set boot-operator-core.controllerManager.enable=true >"$rendered"

deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "boot-operator-controller-manager") | .spec.selector.matchLabels' "$rendered")"
service_selector="$(yq -o=json 'select(.kind == "Service" and .metadata.name == "boot-operator-boot-service") | .spec.selector' "$rendered")"

if [[ -z "$deployment_selector" || -z "$service_selector" ]] || ! diff -u \
  <(printf '%s\n' "$deployment_selector" | jq -S .) \
  <(printf '%s\n' "$service_selector" | jq -S .); then
  echo "FAIL: boot Service selector does not match the upstream Deployment selector"
  exit 1
fi

echo "PASS: boot Service selector matches the upstream Deployment selector"
