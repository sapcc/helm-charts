#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-secrets" init container of the postgres pod.

set -eou pipefail
[[ ${DEBUG:-} != false ]] && set -x

for USER in ${USERS:-}; do
  SECRET="$RELEASE-pguser-$USER"

  # if we already have a secret, we can stop here
  if [[ "$(kubectl get secrets "$SECRET" --ignore-not-found)" != "" ]]; then
    continue
  fi

  # create new secret with randomly generated password
  # NOTE: make sure that the generated password contains no newline
  echo -n "
    apiVersion: v1
    kind: Secret
    metadata:
      name: $SECRET
      ownerReferences:
        - apiVersion: v1
          blockOwnerDeletion: true
          kind: Deployment
          name: $DEPLOYMENT_NAME
          uid: $(kubectl get deployment "$DEPLOYMENT_NAME" -o jsonpath='{.metadata.uid}')
    data:
      postgres-password: $(LC_ALL=C tr -dc '[:graph:]' </dev/urandom | head -c 30 | base64 -w0 | base64 -w0)
  " > secret.yaml
  kubectl create -f secret.yaml
done
