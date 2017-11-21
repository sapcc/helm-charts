#!/bin/bash

{{- if .Values.nova.db_purge.dry_run }}
echo -n "INFO: dry run mode only - "
{{- else }}
echo -n "INFO: "
{{- end }}
echo -n "purging at max {{ .Values.nova.db_purge.max_number }} deleted instances older than {{ .Values.nova.db_purge.older_than }} days from the nova db - "
echo -n `date`
echo -n " - "
{{- if .Values.nova.db_purge.dry_run }}
/var/lib/kolla/venv/bin/nova-manage db purge_deleted_instances --dry-run --older-than {{ .Values.nova.db_purge.older_than }} --max-number {{ .Values.nova.db_purge.max_number }}
{{- else }}
/var/lib/kolla/venv/bin/nova-manage db purge_deleted_instances --older-than {{ .Values.nova.db_purge.older_than }} --max-number {{ .Values.nova.db_purge.max_number }}
{{- end }}
