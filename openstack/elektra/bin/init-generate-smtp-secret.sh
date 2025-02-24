#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-secrets" init container of the elektra pod.
set -eou pipefail
[[ ${DEBUG:-false} != false ]] && set -x

SECRET="elektra-smtp"

# If we already have a secret, we can stop here
if [[ -n "$(kubectl-v1.32.1 get secrets "$SECRET" --ignore-not-found)" ]]; then
  exit 0
fi
