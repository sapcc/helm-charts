#!/usr/bin/env bash
set -euo pipefail

config=(--config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf --config-file=/etc/keystone/keystone.conf.d/upgrade-check.conf)

echo "Checking the upgraded API against the prepared database."
status=0
keystone-status "${config[@]}" upgrade check || status=$?
case "$status" in
    0) ;;
    1) echo "WARNING: Keystone upgrade check reported warnings; continuing." >&2 ;;
    *) echo "ERROR: Keystone upgrade check failed ($status); API will not start." >&2; exit "$status" ;;
esac
