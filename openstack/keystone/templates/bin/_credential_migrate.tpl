#!/usr/bin/env bash

set -e

echo "Running credential_migrate to re-encrypt credentials with current primary key..."
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf credential_migrate --keystone-user keystone --keystone-group keystone

echo "credential_migrate completed successfully."

{{ include "utils.script.job_finished_hook" . | trim }}
