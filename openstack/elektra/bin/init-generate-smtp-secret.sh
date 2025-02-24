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

# Step 0: Set env OS_AUTH_TYPE
export OS_AUTH_TYPE=v3applicationcredential

# Step 1: List ec2 credentials
echo "Listing ec2 credentials..."
openstack ec2 credentials list --user dashboard --user-domain default
echo "Listing ec2 credentials done."

# Step 2: Delete all ec2 credentials

# Step 3: Create ec2 credentials
# echo "Creating EC2 credentials..."
# EC2_CREDS=$(openstack ec2 credentials create --user dashboard --user-domain default --project master --project-domain ccadmin -f json)
# ACCESS_KEY=$(echo "$EC2_CREDS" | jq -r '.access')
# SECRET_KEY=$(echo "$EC2_CREDS" | jq -r '.secret')
# echo "EC2 credentials created."

# Step 4: Authenticate and get OpenStack token
echo "Generating SMTP credentials..."
# SMTP_OUTPUT=$(cronuscli smtp credentials --ec2-access "$ACCESS_KEY" --ec2-secret "$SECRET_KEY")
SMTP_OUTPUT=$(cronuscli smtp credentials --ec2-access 123 --ec2-secret 123)
USERNAME=$(echo "$SMTP_OUTPUT" | grep -oP 'Username:\s+\K.*')
PASSWORD=$(echo "$SMTP_OUTPUT" | grep -oP 'Password:\s+\K.*')
echo "SMTP credentials obtained"

# export OS_TOKEN=$(openstack token issue -f value -c id)

# # Step 5: create new secret with randomly generated token
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
    username: $USERNAME
    password: $PASSWORD
" > secret.yaml
  kubectl create -f secret.yaml