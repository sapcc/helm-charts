#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template argora-operator-remote "$chart_dir" --set mode=seed \
  --set argora-operator-core.manager.enable=true >"$rendered"

deployment_selector="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "argora-operator-controller-manager") | .spec.selector.matchLabels' "$rendered")"

if [[ -z "$deployment_selector" || "$deployment_selector" == "null" ]] || ! printf '%s\n' "$deployment_selector" | jq -e \
  'type == "object" and length > 0 and .["app.kubernetes.io/name"] == "argora-operator-core" and .["control-plane"] == "controller-manager"' >/dev/null; then
  echo "FAIL: argora Deployment selector must be non-empty and contain the upstream controller labels"
  exit 1
fi

echo "PASS: argora Deployment selector contains the upstream controller labels"
