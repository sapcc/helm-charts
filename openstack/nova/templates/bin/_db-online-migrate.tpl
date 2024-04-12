#!/usr/bin/env bash
set -euxo pipefail

# nova-manage has the config for the API DB via /etc/nova/nova.conf.d
# When accessing a cell, we explicitly have to specify the config for the DB.
nova_manage_api="nova-manage"
nova_manage_cell1="nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-cell1.conf"
{{- if .Values.cell2.enabled }}
nova_manage_cell2="nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-{{ .Values.cell2.name }}.conf"
{{- end }}

available_commands_text=$(nova-manage --help | awk '/Command categories/ {getline; print $0}')

{{- if (.Values.imageVersion | hasPrefix "rocky" | not) }}

$nova_manage_cell1 db online_data_migrations

{{- if .Values.cell2.enabled }}
$nova_manage_cell2 db online_data_migrations
{{- end }}
{{- end }}

if echo "${available_commands_text}" | grep -q -E '[{,]placement[},]'; then
  $nova_manage_api placement sync_aggregates
fi

{{ include "utils.script.job_finished_hook" . }}
