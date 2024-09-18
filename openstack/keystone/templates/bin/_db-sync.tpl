#!/usr/bin/env bash

echo "Status before migration:"
keystone-status --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf upgrade check

echo "DB Version before migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync

echo "DB Version after migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

echo "Keystone doctor:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf doctor

{{ include "utils.script.job_finished_hook" . | trim }}

# don't let the doctor break stuff (as usual not qualified enough and you allways need another opinion :P )
exit 0
