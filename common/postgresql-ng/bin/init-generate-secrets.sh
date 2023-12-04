#!/usr/bin/env ash

# This is the entrypoint script for the "generate-secrets" init container of the postgres pod.

set -eou pipefail
[[ -n ${DEBUG:-} ]] && set -x
apk add --no-cache --no-progress kubectl

for USER in postgres ${USERS:-}; do
  SECRET="$RELEASE-pguser-$USER"

  # if we already have a secret, we can stop here
  if [[ "$(kubectl get secrets "$SECRET" --ignore-not-found)" != "" ]]; then
    exit 0
  fi

  # create new secret with randomly generated password
  echo "
    apiVersion: v1
    kind: Secret
    metadata:
      name: $SECRET
      ownerReferences:
        - apiVersion: v1
          kind: Deployment
          name: $RELEASE-postgresql
          uid: $(kubectl get deployment "$RELEASE-postgresql" -o jsonpath='{.metadata.uid}')
    data:
      postgres-password: $(head -c 30 </dev/urandom | base64)
  " > secret.yaml
  kubectl create -f secret.yaml
done
