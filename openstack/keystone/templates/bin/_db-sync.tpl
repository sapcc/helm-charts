#!/usr/bin/env bash

set -ex

{{- if or (eq .Values.release "mitaka") (eq .Values.release "newton") }}
{{- if eq .Values.release "newton" }}
keystone-manage --config-file=/etc/keystone/keystone.conf doctor
{{- end }}
keystone-manage --config-file=/etc/keystone/keystone.conf db_sync
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
