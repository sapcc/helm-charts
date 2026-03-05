#!/usr/bin/env ash
# shellcheck shell=ash
# shellcheck disable=SC3010

# This is the entrypoint script for the elektra token rotation.
set -eou pipefail
[[ ${DEBUG:-} != false ]] && set -x

SECRET="elektra-token"

# creates a new secret key
# double base64 encode to get a string without newlines and 128 characters long after being decoded when deploying
# 96×3/4 = 128 characters
SECRET_KEY_BASE=$(head -c 96 /dev/urandom | base64 -w 0 | tr -d '\n' | base64 -w 0)

# updates secret with randomly generated token
echo -n "
  apiVersion: v1
  kind: Secret
  metadata:
    name: $SECRET
    ownerReferences:
      - apiVersion: apps/v1
        blockOwnerDeletion: true
        kind: Deployment
        name: elektra
        uid: $(kubectl get deployment elektra -o jsonpath='{.metadata.uid}')
  data:
    token: $SECRET_KEY_BASE
" > secret.yaml
  kubectl apply -f secret.yaml

