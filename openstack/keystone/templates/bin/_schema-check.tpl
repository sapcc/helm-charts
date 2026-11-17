#!/usr/bin/env bash
set -euo pipefail

config=(--config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf --config-file=/etc/keystone/keystone.conf.d/upgrade-check.conf)

# kubernetes-entrypoint handles migration ordering; assert readiness once.
# See https://docs.openstack.org/keystone/pike/admin/identity-upgrading.html#using-db-sync-check
# Accept a current schema (0) or expansion with contraction pending (4).
status=0
keystone-manage "${config[@]}" db_sync --check || status=$?
if [[ "$status" != 0 && "$status" != 4 ]]; then
    echo "Database expansion has not completed (schema check: $status)." >&2
    exit "$status"
fi
