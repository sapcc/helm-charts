#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if grep -Eq '^[[:space:]]*mode:' "$chart_dir/values.yaml"; then
  echo "FAIL: values.yaml must not declare mode"
  exit 1
fi

helm template "$chart_dir" >/dev/null
echo "PASS: chart has no mode default and renders without mode"
