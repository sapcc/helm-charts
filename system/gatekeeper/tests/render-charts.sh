#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

if hash u8s &>/dev/null; then
  : "${HELM:=u8s helm3 --}"
else
  : "${HELM:=helm}"
fi

(
  cd ..
  [[ ! -d charts ]] && ${HELM} dep up >/dev/null
  ${HELM} template gatekeeper . --values ci/test-values.yaml --output-dir tests/rendered-chart >/dev/null

  # unwrap delayed-payload ConfigMaps (`gator` needs to see the raw constraint resource)
  mkdir -p tests/rendered-chart/gatekeeper/constraints
  for KEY in $(yq -r '.data | keys | .[]' < tests/rendered-chart/gatekeeper/templates/configmap-delayed-payloads.yaml); do
    yq -o json < tests/rendered-chart/gatekeeper/templates/configmap-delayed-payloads.yaml | \
      jq --arg key "$KEY" -r '.data[$key]' > "tests/rendered-chart/gatekeeper/constraints/$KEY"
  done
)
