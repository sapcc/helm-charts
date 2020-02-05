#!/bin/sh
set -euo pipefail

state=$(curl -s http://localhost:22222/state/get_state | sed 's/State: //')
if [ ${state} != "NORMAL" ]; then
  exit 1
fi
