#!/usr/bin/env bash
set -euo pipefail

echo "INFO: Erroring out all orphaned migrations"
exec nova-manage db error_out_orphaned_migrations
