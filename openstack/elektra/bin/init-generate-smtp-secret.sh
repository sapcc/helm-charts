#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-secrets" init container of the elektra pod.
set -eou pipefail
[[ ${DEBUG:-false} != false ]] && set -x

export OS_AUTH_TYPE=v3applicationcredential
SECRET="elektra-smtp"

# If we already have a secret, we can extract the ec2 access key
if [[ -n "$(kubectl-v1.32.1 get secrets "$SECRET" --ignore-not-found)" ]]; then
  EC2_ACCESS_KEY=$(kubectl-v1.32.1 get secret "$SECRET" -o jsonpath='{.data.ec2_access_key}' | base64 --decode)
  # Remove secret and ec2 credentials
  kubectl-v1.32.1 delete secret "$SECRET"
  openstack ec2 credentials delete --user dashboard --user-domain default $EC2_ACCESS_KEY
fi

# Step 1: List ec2 credentials
echo "Listing ec2 credentials..."
openstack ec2 credentials list --user dashboard --user-domain default
echo "Listing ec2 credentials done."

# Step 3: Create ec2 credentials
echo "Creating EC2 credentials..."
EC2_CREDS=$(openstack ec2 credentials create --user dashboard --user-domain default --project master --project-domain ccadmin -f json)
ACCESS_KEY=$(echo "$EC2_CREDS" | jq -r '.access')
SECRET_KEY=$(echo "$EC2_CREDS" | jq -r '.secret')
echo "EC2 credentials created."

# Step 4: Authenticate and get OpenStack token
echo "Generating SMTP credentials..."
SMTP_OUTPUT=$(cronuscli smtp credentials --ec2-access "$ACCESS_KEY" --ec2-secret "$SECRET_KEY")
USERNAME=$(echo "$SMTP_OUTPUT" | grep -oP 'Username:\s+\K.*')
PASSWORD=$(echo "$SMTP_OUTPUT" | grep -oP 'Password:\s+\K.*')
echo "SMTP credentials obtained"

# Step 5: create new secret with randomly generated token
# ec2_access_key: $ACCESS_KEY
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
        uid: $(kubectl-v1.32.1 get deployment elektra -o jsonpath='{.metadata.uid}')
  data:
    ec2_access_key: $ACCESS_KEY
    username: $USERNAME
    password: $PASSWORD
" > secret.yaml
  kubectl-v1.32.1 create -f secret.yaml