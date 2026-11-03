#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template disco-ddo "$chart_dir" --set mode=seed --set apiServerHost=ci.example.com >"$rendered"

deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "disco-controller-manager") | .spec.selector.matchLabels' "$rendered")"

if [[ -z "$deployment_selector" || "$deployment_selector" == "null" ]] || ! printf '%s\n' "$deployment_selector" | jq -e \
  '. == {"app":"disco"}' >/dev/null; then
  echo "FAIL: disco-controller-manager Deployment selector must be exactly {app: disco}"
  exit 1
fi
echo "PASS: disco-controller-manager Deployment selector is exactly {app: disco}"
