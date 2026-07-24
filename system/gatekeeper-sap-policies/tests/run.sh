#!/usr/bin/env bash

# Usage: ./run.sh [extra gator args]
set -euo pipefail

cd "$(dirname "$0")"

rm -rf rendered
helm template .. -f values-test.yaml --output-dir rendered >/dev/null

gator verify -v . "$@"
