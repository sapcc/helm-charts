#!/usr/bin/env bash
set -eou pipefail

# This test validates the processing_rules and merging_rules in templates/configmap-doop-analyzer.yaml by running
# `doop-analyzer process-once` using that config on the input files at */input.json and checking that the expected
# output at */output.json is obtained. The test case directories are named after the rules that they test.
#
# To build a new test case, you can obtain a suitable input.json from a real cluster by grabbing its doop-analyzer
# config (`k -n kube-system get cm doop-analyzer`), adding the `kubernetes:` section for use with kubectl credentials
# (see doop-analyzer README for details), and then running `doop-analyzer collect-once config.yaml > input.json`.
# Truncate and redact the result as required.

cd "$(dirname "$0")"

CONFIG_FILE=../rendered-chart/gatekeeper/doop-analyzer-config.json
yq -r '.data["config.json"]' ../rendered-chart/gatekeeper/templates/configmap-doop-analyzer.yaml > "$CONFIG_FILE"

EXIT_CODE=0
for INPUT_FILE in */input.json; do
  TEST_NAME="$(dirname "$INPUT_FILE")"
  OUTPUT_FILE="$TEST_NAME/output.json"

  if ! doop-analyzer process-once "$CONFIG_FILE" < "$INPUT_FILE" > "$OUTPUT_FILE.actual"; then
    printf '\x1B[1;31m-- FAIL:\x1B[0;31m %s (doop-analyzer exited with error)\x1B[0m\n' "$TEST_NAME"
    EXIT_CODE=1
    continue
  fi

  if diff -u "$OUTPUT_FILE" "$OUTPUT_FILE.actual"; then
    echo "-- PASS: $TEST_NAME"
  else
    printf '\x1B[1;31m-- FAIL:\x1B[0;31m %s (output file does not match expectation)\x1B[0m\n' "$TEST_NAME"
    EXIT_CODE=1
  fi
done

exit "$EXIT_CODE"
