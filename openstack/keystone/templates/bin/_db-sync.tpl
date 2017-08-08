#!/usr/bin/env bash

set -ex

keystone-manage --config-file=/etc/keystone/keystone.conf db_sync
