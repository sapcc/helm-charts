#!/usr/bin/env bash

echo "DB Version before migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf db_version

{{- if (eq .Values.release "newton") }}
keystone-manage --config-file=/etc/keystone/keystone.conf db_sync
{{ else }}
{{- if eq .Values.release "queens" }}
keystone-manage-extension --config-file=/etc/keystone/keystone.conf drop_ocata_deprecated_ldap_domain_config
{{- end }}
set +ex
keystone-manage --config-file=/etc/keystone/keystone.conf db_sync --check
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
        keystone-manage --config-file=/etc/keystone/keystone.conf db_sync --expand
        ;&
    3)
        echo "Database expanded"
        # run migrate
        keystone-manage --config-file=/etc/keystone/keystone.conf db_sync --migrate
        ;&
    4)
        echo "Database migrated"
        # run contraction
        keystone-manage --config-file=/etc/keystone/keystone.conf db_sync --contract
        ;;
    *)
        echo "Duno what state the database is in. grrrr"
        ;;
esac
{{- end }}

echo "DB Version after migration:"
keystone-manage --config-file=/etc/keystone/keystone.conf db_version

keystone-manage --config-file=/etc/keystone/keystone.conf doctor

# don't let the doctor break stuff (as usual not qualified enough and needs another opinion :P )
exit 0


