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

# Step 1: Authenticate and get OpenStack token
echo "Fetching OpenStack token..."
export OS_TOKEN=$(openstack token issue -f value -c id)

# Step 2: List ec2 credentials
echo "Listing ec2 credentials..."
openstack ec2 credentials list --user dashboard --user-domain default