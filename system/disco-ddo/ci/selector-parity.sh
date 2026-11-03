#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template disco-ddo "$chart_dir" --set mode=seed >"$rendered"

deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "disco-controller-manager") | .spec.selector.matchLabels' "$rendered")"

if [[ -z "$deployment_selector" || "$deployment_selector" == "null" ]] || ! printf '%s\n' "$deployment_selector" | jq -e \
  'type == "object" and length > 0 and .["app"] == "disco"' >/dev/null; then
  echo "FAIL: disco-controller-manager Deployment selector must contain app=disco"
  exit 1
fi

echo "PASS: disco-controller-manager Deployment selector contains app=disco"
