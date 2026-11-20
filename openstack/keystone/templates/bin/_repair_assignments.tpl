#!/usr/bin/env bash

# repair any role-assignments that point to orphaned objects (usually from users that have been deactivated by CAM)
keystone-manage-extension --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf repair_assignments {{ if .Values.skipRepairRoleAssignments }} --dry-run {{ end }}
exit_code=$?
{{- include "utils.script.job_finished_hook" . | nindent 0 }}
exit $exit_code
