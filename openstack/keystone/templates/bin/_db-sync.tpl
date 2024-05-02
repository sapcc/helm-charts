#!/usr/bin/env bash

echo "Status before migration:"
keystone-status --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf upgrade check

echo "DB Version before migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync --check
case $? in
    0)
        echo "No migration required. Database is up-2-date."
        ;;
    1)
        echo "Uhoh, Houston we have a problem."
        ;;
    2)
        echo "Database update available - starting migrations"
        # expand the database schema
        keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync --expand
        ;&
    3)
        echo "Database expanded"
        # run migrate
        keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync --migrate
        ;&
    4)
        echo "Database migrated"
        # run contraction
        keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_sync --contract
        ;;
    *)
        echo "Duno what state the database is in. grrrr"
        ;;
esac

echo "DB Version after migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf db_version

echo "Keystone doctor:"
keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf doctor

{{ include "utils.script.job_finished_hook" . | trim }}

# don't let the doctor break stuff (as usual not qualified enough and you allways need another opinion :P )
exit 0
