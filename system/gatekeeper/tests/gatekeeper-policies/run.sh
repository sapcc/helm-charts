#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 helm-manifest-parser 127.0.0.1:8080 &
pid_helm_manifest_parser=$!
FAST_SHUTDOWN=1 LOG_ALL_REQUESTS=1 doop-image-checker 127.0.0.1:8081 response-config.yaml &
pid_doop_image_checker=$!
# shellcheck disable=SC2064
trap "kill $pid_helm_manifest_parser $pid_doop_image_checker && sleep 0.5" INT TERM ERR EXIT

gator verify -v . "$@"
