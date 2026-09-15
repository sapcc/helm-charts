#!/usr/bin/env bash
set -euxo pipefail

# nova-manage has the config for the API DB via /etc/nova/nova.conf.d
# When accessing a cell, we explicitly have to specify the config for the DB.
nova_manage_api="nova-manage"
{{- $cellsNonzero := include "nova.helpers.cell_ids_nonzero" . | fromJsonArray }}
{{- $envAll := . }}
{{- range $cellId := $cellsNonzero }}
{{- $cellName := include "nova.helpers.cell_name" (tuple $envAll $cellId) }}
nova_manage_{{ $cellId }}="nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-{{ $cellName }}.conf"
{{- end }}

available_commands_text=$(nova-manage --help | awk '/Command categories/ {getline; print $0}')
{{ range $cellId := $cellsNonzero }}
$nova_manage_{{ $cellId }} db online_data_migrations
{{- end }}

if echo "${available_commands_text}" | grep -q -E '[{,]placement[},]'; then
  $nova_manage_api placement sync_aggregates
fi

{{ include "utils.script.job_finished_hook" . }}
