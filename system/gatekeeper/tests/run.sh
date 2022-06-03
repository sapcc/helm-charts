#!/usr/bin/env bash
set -eou pipefail

cd "$(dirname "$0")"

LOG_ALL_REQUESTS=1 helm-manifest-parser 127.0.0.1:8080 &
pid=$!
# shellcheck disable=SC2064
trap "kill $pid" INT TERM EXIT

(
  cd ..
  helm dep up >/dev/null
  helm template gatekeeper . --values ci/test-values.yaml --output-dir tests/rendered-chart >/dev/null
)

(
  cd ../../gatekeeper-config
  helm dep up >/dev/null
  helm template gatekeeper-config . --values ci/test-values.yaml --output-dir ../gatekeeper/tests/rendered-chart >/dev/null
)

for file in fixtures/*/*.in.yaml; do
  basename="$(basename "$file")"
  out_file="$(dirname "$file")/${basename//.in.yaml/}.out.yaml"
  ./inject-fixture-into-helm-release.sh "$file" >"$out_file"
done

gator verify -v .
