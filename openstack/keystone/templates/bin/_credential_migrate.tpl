#!/usr/bin/env bash

set -euo pipefail

finish() {
    status=$?
    trap - EXIT
    set +e
    {{- include "utils.script.job_finished_hook" . | nindent 4 }}
    exit "$status"
}
trap finish EXIT

echo "Running credential_migrate to re-encrypt credentials with current primary key..."
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf credential_migrate --keystone-user keystone --keystone-group keystone

echo "credential_migrate completed successfully."
