#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm template kube-state-metrics-remote-ddo "$chart_dir" --set mode=seed >"$rendered"

sel="$(yq -o=json 'select(.kind == "Deployment" and .metadata.name == "kube-state-metrics-remote") | .spec.selector.matchLabels' "$rendered")"

if [[ -z "$sel" || "$sel" == "null" ]] || ! printf '%s\n' "$sel" | jq -e \
  '."app.kubernetes.io/name" == "kube-state-metrics-remote" and ."app.kubernetes.io/instance" == "kube-state-metrics-remote"' >/dev/null; then
  echo "FAIL: kube-state-metrics-remote Deployment selector must carry name=instance=kube-state-metrics-remote"
  exit 1
fi
echo "PASS: kube-state-metrics-remote Deployment selector matches legacy"
