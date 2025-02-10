#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-secrets" init container of the elektra pod.

set -eou pipefail
[[ ${DEBUG:-} != false ]] && set -x

OLD_SECRET="$RELEASE"
SECRET="$RELEASE-secrets"

# if we already have a secret, we can stop here
if [[ "$(kubectl get secrets "$SECRET" --ignore-not-found)" != "" ]]; then
  exit 0
fi

# sets a new secret key
# double base64 encode to get a string without newlines and 128 characters long after being decoded when deploying
SECRET_KEY_BASE=$(head -c 96 /dev/urandom | base64 -w 0 | tr -d '\n' | base64 -w 0)

# check if the old secret exists and if it does, copy the token from it
if [[ -n "$(kubectl get secret "$OLD_SECRET" --ignore-not-found)" ]]; then
  EXISTING_TOKEN=$(kubectl get secret "$OLD_SECRET" -o jsonpath="{.data.monsoon\.rails\.secret\.token}" 2>/dev/null || echo "")
  if [[ -n "$EXISTING_TOKEN" ]]; then
    SECRET_KEY_BASE=$EXISTING_TOKEN
  fi
fi

# create new secret with randomly generated token
echo -n "
  apiVersion: v1
  kind: Secret
  metadata:
    name: $SECRET
    ownerReferences:
      - apiVersion: apps/v1
        blockOwnerDeletion: true
        kind: Deployment
        name: $DEPLOYMENT_NAME
        uid: $(kubectl get deployment "$DEPLOYMENT_NAME" -o jsonpath='{.metadata.uid}')
  data:
    token: $SECRET_KEY_BASE
" > secret.yaml
  kubectl create -f secret.yaml

