#!/bin/sh

set -x
set -e

nova-manage --config-file /etc/nova/nova.conf db online_data_migrations

