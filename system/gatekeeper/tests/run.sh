#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

if hash u8s &>/dev/null; then
  : "${HELM:=u8s helm3 --}"
else
  : "${HELM:=helm}"
fi

FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 helm-manifest-parser 127.0.0.1:8080 &
pid_helm_manifest_parser=$!
FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 doop-image-checker 127.0.0.1:8081 response-config.yaml &
pid_doop_image_checker=$!
# shellcheck disable=SC2064
trap "kill $pid_helm_manifest_parser $pid_doop_image_checker && sleep 0.5" INT TERM ERR EXIT

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

gator verify -v . "$@"
