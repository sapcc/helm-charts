#!/usr/bin/env bash

set -ex

{{- if not (eq .Values.release "pike") }}
keystone-manage --config-file=/etc/keystone/keystone.conf db_sync
{{- if eq .Values.release "ocata" }}
keystone-manage-extension --config-file=/etc/keystone/keystone.conf drop_ocata_deprecated_ldap_domain_config
{{- end }}
{{ else }}
state=$(keystone-manage --config-file=/etc/keystone/keystone.conf db_sync --check)
case $state in
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
