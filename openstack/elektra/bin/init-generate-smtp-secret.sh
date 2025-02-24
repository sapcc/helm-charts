#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-secrets" init container of the elektra pod.
set -eou pipefail
[[ ${DEBUG:-} != false ]] && set -x

SECRET="elektra-smtp"

# if we already have a secret, we can stop here
if [[ "$(kubectl get secrets "$SECRET" --ignore-not-found)" != "" ]]; then
  exit 0
fi
