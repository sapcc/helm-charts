#!/usr/bin/env bash

set -e

for f in /glance-etc/*; do
    cp $f /etc/glance
done

exec /var/lib/kolla/venv/bin/glance-registry
