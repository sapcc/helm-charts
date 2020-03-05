#!/usr/bin/env bash
set -e
set -x

nova-manage api_db sync
nova-manage db sync --local_cell
nova-manage db null_instance_uuid_scan --delete

# online data migration run by online-migration-job
