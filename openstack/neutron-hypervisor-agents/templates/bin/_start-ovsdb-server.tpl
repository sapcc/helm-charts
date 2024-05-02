#!/usr/bin/env bash
set -eEuo pipefail

if pgrep -f /usr/sbin/ovsdb-server; then
    echo "Waiting to be the only highlander"
    exit 1
fi

mkdir -p /run/openvswitch
[ -f /var/lib/openvswitch/conf.db ] || ovsdb-tool create

exec /usr/sbin/ovsdb-server \
    --remote=punix:/run/openvswitch/db.sock --pidfile \
    -vconsole:emer -vsyslog:err -vfile:off
