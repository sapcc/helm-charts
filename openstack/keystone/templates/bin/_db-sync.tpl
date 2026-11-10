#!/usr/bin/env bash
set -e

echo "DB Version before migration:"
status=0
db_version_output=$(keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version) || status=$?
printf '%s\n' "$db_version_output"
if [ $status -ne 0 ]; then
  echo "ERROR: DB version check failed with exit code $status. Aborting."
  exit $status
fi

# Logging may also go to stdout; db_version prints the revision on the last line.
db_version=${db_version_output##*$'\n'}
if [ "$db_version" = "None" ]; then
  echo "No DB migration version recorded. Skipping pre-upgrade check for initial schema creation."
else
  echo "Status before migration:"
  status=0
  keystone-status --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf upgrade check || status=$?
  if [ $status -eq 2 ]; then
    echo "ERROR: upgrade check failed with exit code 2. Aborting."
    exit 2
  elif [ $status -eq 1 ]; then
    echo "WARNING: upgrade check returned warning (exit code 1). Continuing."
  elif [ $status -ne 0 ]; then
    echo "ERROR: upgrade check failed with exit code $status. Aborting."
    exit $status
  fi
fi

keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync

echo "DB Version after migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

echo "Keystone doctor:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf doctor

{{ include "utils.script.job_finished_hook" . | trim }}
