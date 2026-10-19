#!/usr/bin/env bash
set -euo pipefail

HELM=(helm)
if hash u8s &>/dev/null; then
  HELM=(u8s helm3 '--')
fi

"${HELM[@]}" repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
"${HELM[@]}" pull gatekeeper/gatekeeper --untar --destination vendor/
rm -rf -- vendor/gatekeeper-upstream
mv vendor/gatekeeper vendor/gatekeeper-upstream
