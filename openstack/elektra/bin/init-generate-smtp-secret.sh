#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC3010

# This is the entrypoint script for the "generate-smpt-secret" init container of the elektra pod.
set -eou pipefail
[[ ${DEBUG:-false} != false ]] && set -x

export OS_AUTH_TYPE=v3applicationcredential
SECRET="elektra-smtp"

# if we already have a secret, we can stop here
if [[ -n "$(/usr/bin/kubectl get secrets "$SECRET" --ignore-not-found)" ]]; then
  exit 0
fi

# Step 2: Create ec2 credentials
echo "Creating EC2 credentials..."
EC2_CREDS=$(openstack ec2 credentials create --user dashboard --user-domain default --project master --project-domain ccadmin -f json)
ACCESS_KEY=$(echo "$EC2_CREDS" | jq -r '.access')
SECRET_KEY=$(echo "$EC2_CREDS" | jq -r '.secret')
PROJECT_ID=$(echo "$EC2_CREDS" | jq -r '.project_id')
USER_ID=$(echo "$EC2_CREDS" | jq -r '.user_id')
echo "EC2 credentials created."

# Step 3: Generating SMTP
echo "Generating SMTP credentials..."
SMTP_OUTPUT=$(cronuscli smtp credentials --ec2-access "$ACCESS_KEY" --ec2-secret "$SECRET_KEY" --project-id "$PROJECT_ID" --user-id "$USER_ID" --base64 )
USERNAME=$(echo "$SMTP_OUTPUT" | grep -oP 'Username:\s+\K.*')
PASSWORD=$(echo "$SMTP_OUTPUT" | grep -oP 'Password:\s+\K.*')
echo "SMTP credentials obtained"

# Step 4: create new secret with smtp credentials and id from ec2 credentials
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
        uid: $(/usr/bin/kubectl get deployment elektra -o jsonpath='{.metadata.uid}')
  data:
    ec2_access_key: $ACCESS_KEY
    username: $USERNAME
    password: $PASSWORD
" > secret.yaml
  
if ! /usr/bin/kubectl create -f secret.yaml; then
  echo "Failed to create secret, likely because it already exists. Deleting associated EC2 credentials..."
  openstack ec2 credentials delete --user dashboard --user-domain default $ACCESS_KEY
else
  echo "Secret created successfully."
fi