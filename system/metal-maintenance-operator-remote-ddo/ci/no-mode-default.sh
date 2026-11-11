#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Gate 1: values.yaml must not declare a default for mode.
# The dual-deployment-operator injects .Values.mode at render time; a chart-level
# default causes the operator to reject the render.
if grep -Eq '^[[:space:]]*mode:' "$chart_dir/values.yaml"; then
  echo "FAIL: values.yaml must not declare mode"
  exit 1
fi

# Gate 2: helm template must succeed (no template syntax errors).
render="$(helm template "$chart_dir")"

# Gate 3: the no-mode render must contain ZERO objects carrying the SAP additions
# annotation (dual-deployment-operator.cc.sap/origin: additions).
# Additions templates (Tasks 2-4) are the only operand-authored, mode-guarded objects;
# a miswritten guard (e.g. `{{ if .Values.mode }}` instead of `{{ if eq .Values.mode "seed" }}`)
# would leak SAP-authored objects when mode is unset — the real hazard this gate exists to catch.
# Note: subchart baseline objects (RBAC, telemetry Service, etc.) have no mode guard and will
# always appear in the no-mode render; that is BY DESIGN — DDO suppresses/drives them per-mode
# via CR flags. They do NOT carry origin: additions and are NOT a gate failure.
if echo "$render" | grep -q 'dual-deployment-operator.cc.sap/origin: additions'; then
  echo "FAIL: no-mode render contains additions-origin objects — a mode guard is miswritten"
  exit 1
fi

echo "PASS: no mode default; no additions leak without mode"
