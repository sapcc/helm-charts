#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

# This runs the testsuite of the "gatekeeper-policies" subchart, by extracting it and invoking the Makefile contained within.
[ -d extracted-chart/ ] && rm -r extracted-chart
mkdir -p extracted-chart
( cd extracted-chart && tar xf ../../charts/gatekeeper-policies-*.tgz )
make -C extracted-chart/gatekeeper-policies check
