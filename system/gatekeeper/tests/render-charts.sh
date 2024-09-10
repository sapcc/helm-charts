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
)

(
  cd ../../gatekeeper-config
  [[ ! -d charts ]] && ${HELM} dep up >/dev/null
  ${HELM} template gatekeeper-config . --values ci/test-values.yaml --output-dir ../gatekeeper/tests/rendered-chart >/dev/null
)
