#!/usr/bin/env bash
set -euo pipefail

archive_before=$(date -u --date "{{ .Values.nanny.db_archive_deleted_rows.older_than }} days ago" \
  "+%Y-%m-%d %H:%M:%S")
echo "INFO: archiving db rows deleted before ${archive_before} to shadow tables with batch size" \
  "{{ .Values.nanny.db_archive_deleted_rows.max_rows }}"

# Command "nova-manage db archive_deleted_rows" returns exit code 1 if rows were
# archived. Catch this to prevent job failure.
nova-manage db archive_deleted_rows --until-complete --max_rows {{ .Values.nanny.db_archive_deleted_rows.max_rows }} \
  --all-cells --verbose --before "${archive_before}" || [[ "$?" == "1" ]]
