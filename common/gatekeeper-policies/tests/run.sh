#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

if hash u8s &>/dev/null; then
  : "${HELM:=u8s helm3 --}"
else
  : "${HELM:=helm}"
fi

# render the test chart (gator needs Constraint and ConstraintTemplate objects that do not have Helm templating in them)
(
  cd chart
  ${HELM} dep up >/dev/null # ensure that we are using the newest version of the "gatekeeper-policies" chart
  ${HELM} template rendered-chart . --output-dir .. >/dev/null
)

# run auxiliary components that some policies reference via http.send()
FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 helm-manifest-parser 127.0.0.1:8080 &
pid_helm_manifest_parser=$!
FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 doop-image-checker 127.0.0.1:8081 <(yq -oj < response-config.yaml) &
pid_doop_image_checker=$!
# shellcheck disable=SC2064
trap "kill $pid_helm_manifest_parser $pid_doop_image_checker && sleep 0.5" INT TERM ERR EXIT

# run test suite
gator verify -v . "$@"
