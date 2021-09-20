#!/usr/bin/env bash
# source https://github.com/aws-containers/amazon-ecr-public-creds-helper-script-for-k8s/blob/main/entrypoint.sh

set -euo pipefail

REGISTRY=https://public.ecr.aws
AUTH_USER=AWS
AUTH_TOKEN=$(aws ecr-public get-authorization-token --region us-east-1 --output=text --query 'authorizationData.authorizationToken' | base64 -d | cut -d: -f2)

for n in $(echo ${TARGET_NAMESPACES})
do
    kubectl delete secret ecr-public-token \
        -n "${n}" \
        --ignore-not-found
    kubectl create secret docker-registry ecr-public-token \
        -n "${n}" \
        --docker-server=${REGISTRY} \
        --docker-username=${AUTH_USER} \
        --docker-password=${AUTH_TOKEN}
done
