#!/usr/bin/env bash

set -e

for f in /glance-etc/*; do
    cp $f /etc/glance
done

#chown -R glance: /glance_store
exec  /var/lib/kolla/venv/bin/glance-api
