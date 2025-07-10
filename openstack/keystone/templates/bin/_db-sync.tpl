#!/usr/bin/env bash

echo "Status before migration:"
keystone-status --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf upgrade check
status=$?
if [ $status -eq 2 ]; then
  echo "ERROR: upgrade check failed with exit code 2. Aborting."
  exit 2
elif [ $status -eq 1 ]; then
  echo "WARNING: upgrade check returned warning (exit code 1). Continuing."
elif [ $status -ne 0 ]; then
  echo "ERROR: upgrade check failed with exit code $status. Aborting."
  exit $status
fi

set -e

echo "DB Version before migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync

echo "DB Version after migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

set +e
echo "Keystone doctor:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf doctor

{{ include "utils.script.job_finished_hook" . | trim }}
