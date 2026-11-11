#!/usr/bin/env bash
set -euo pipefail

chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Gate 1: values.yaml must not declare a default for mode (any form).
# Uses yq has() so quoted, null, or empty forms are all caught — not just
# the bare `mode: <value>` that a simple grep would miss.
if [ "$(/opt/homebrew/bin/yq 'has("mode")' "$chart_dir/values.yaml")" = "true" ]; then
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
#
# Implementation: use yq eval-all over the multi-document stream so the check is
# quote-insensitive (catches both `origin: additions` and `origin: "additions"`).
# Documents with null metadata/annotations are handled gracefully (yq returns null,
# which does not equal "additions", so the select() produces no output).
leak="$(printf '%s' "$render" | \
  yq eval-all '[.metadata.annotations."dual-deployment-operator.cc.sap/origin"] | .[] | select(. == "additions")' - \
  2>/dev/null | head -1)"
if [ -n "$leak" ]; then
  echo "FAIL: no-mode render contains additions-origin objects — a mode guard is miswritten"
  exit 1
fi

echo "PASS: no mode default; no additions leak without mode"
