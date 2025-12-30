#!/usr/bin/env bash
set -euo pipefail

purge_before=$(date -u --date "{{ .Values.nanny.db_archive_deleted_rows_cell0.older_than }} days ago" \
  "+%Y-%m-%d %H:%M:%S")
echo "INFO: purging cell0 db rows deleted before ${purge_before} with --purge flag"

# Command "nova-manage db archive_deleted_rows" returns exit code 1 if rows were
# archived/purged. Catch this to prevent job failure.
# Note: We use --purge to immediately delete rows instead of archiving to shadow tables.
# This only runs for cell0, not all cells.
nova-manage db archive_deleted_rows --until-complete --max_rows {{ .Values.nanny.db_archive_deleted_rows_cell0.max_rows }} \
  --verbose --before "${purge_before}" --purge || [[ "$?" == "1" ]]
