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
SECRET_KEY_BASE=$(head -c 64 /dev/urandom | base64 | tr -d '\n' | cut -c1-64)

# check if the old secret exists and if it does, copy the token from it
if kubectl get secret "$OLD_SECRET" >/dev/null 2>&1; then
  EXISTING_TOKEN=$(kubectl get secret "$OLD_SECRET" -o jsonpath="{.data.monsoon\.rails\.secret\.token}" 2>/dev/null || echo "")
  if [[ -n "$EXISTING_TOKEN" ]]; then
    # Decode the existing token (Kubernetes stores secrets in base64)
    SECRET_KEY_BASE=$(echo "$EXISTING_TOKEN" | base64 -d)    
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
    token: $(head -c 64 /dev/urandom | base64 | tr -d '\n' | cut -c1-64)
" > secret.yaml
  kubectl create -f secret.yaml

