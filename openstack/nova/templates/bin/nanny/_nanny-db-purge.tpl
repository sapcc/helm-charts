#!/usr/bin/env bash
set -euo pipefail

purge_before=$(date -u --date "{{ .Values.nanny.db_purge.older_than }} days ago" \
  "+%Y-%m-%d %H:%M:%S")
echo "INFO: purging archived db rows deleted before ${purge_before} from shadow tables"

# Command "nova-manage db purge" returns exit code 3 if no rows were deleted.
# Catch this to prevent script failure.
nova-manage db purge --verbose --all-cells --before "${purge_before}" || [[ "$?" == "3" ]]
