#!/bin/bash
set -euo pipefail

# nova-manage has the config for the API DB via /etc/nova/nova.conf.d
# When accessing a cell, we explicitly have to specify the config for the DB.
nova_manage_api="nova-manage"
nova_manage_cell1="nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-cell1.conf"
{{- if .Values.cell2.enabled }}
nova_manage_cell2="nova-manage --config-file /etc/nova/nova.conf --config-file /etc/nova/nova-{{ .Values.cell2.name }}.conf"
{{- end }}

# First create/update the api db, as it contains the cell-mappings
$nova_manage_api api_db sync

# Now update the cell-mappings
update_cell() {
  cell_name="${1}"; shift
  cell_uuid="${1}"; shift
  transport_url="${1}"; shift
  wanted_transport_url="${1}"; shift
  database_connection="${1}"; shift
  wanted_database_connection="${1}"; shift

  needs_update="false"
  if [ "${transport_url}" != "${wanted_transport_url}" ]; then
    needs_update="true"
    echo "Updating ${cell_name} transport-url..."
  fi
  if [ "${database_connection}" != "${wanted_database_connection}" ]; then
    needs_update="true"
    echo "Updating ${cell_name} database_connection..."
  fi
  if [ "${needs_update}" = "true" ]; then
    $nova_manage_api cell_v2 update_cell \
        --cell_uuid ${cell_uuid} \
        --transport-url "${wanted_transport_url}" \
        --database_connection "${wanted_database_connection}"
  fi
}


get_connection_from_file() {
	file="${1}"
	python3 <<-EOF
		from configparser import ConfigParser
		c = ConfigParser()
		c.read("${file}")
		print(c['database']['connection'])
	EOF
}


get_transport_url_from_file() {
	file="${1}"
	python3 <<-EOF
		from configparser import ConfigParser
		c = ConfigParser()
		c.read("${file}")
		print(c['DEFAULT']['transport_url'])
	EOF
}


found_cell0="false"
found_cell1="false"
found_cell2="false"
while read line; do
  cell_name=$(echo "$line" | cut -d'|' -f2 | tr -d '[:space:]')
  cell_uuid=$(echo "$line" | cut -d'|' -f3 | tr -d '[:space:]')
  transport_url=$(echo "$line" | cut -d'|' -f4 | tr -d '[:space:]')
  database_connection=$(echo "$line" | cut -d'|' -f5 | tr -d '[:space:]')
  echo "Processing Cell $cell_uuid"

  if [ "${cell_name}" = "None" ]; then
    echo "Renaming default cell to cell1"
    $nova_manage_api cell_v2 update_cell --cell_uuid $cell_uuid --name "cell1"
    cell_name="cell1"
  fi

  case "${cell_name}" in
    cell0)
      found_cell0="true"
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "none:/" \
            "${database_connection}" "$(get_connection_from_file /etc/nova/nova-cell0.conf)"
      ;;
    cell1)
      found_cell1="true"
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "$(get_transport_url_from_file /etc/nova/nova-cell1.conf)" \
            "${database_connection}" "$(get_connection_from_file /etc/nova/nova-cell1.conf)"
      ;;
{{ if .Values.cell2.enabled }}
    {{.Values.cell2.name}})
      found_cell2="true"
      echo "Found existing cell2..."
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "$(get_transport_url_from_file /etc/nova/nova-{{ .Values.cell2.name }}.conf)" \
            "${database_connection}" "$(get_connection_from_file /etc/nova/nova-{{ .Values.cell2.name }}.conf)"
      ;;
{{- end }}
  esac
done < <($nova_manage_api cell_v2 list_cells --verbose | grep ':/')

if [ "${found_cell0}" = "false" ]; then
  echo "Creating cell0..."
  $nova_manage_api cell_v2 map_cell0 \
      --database_connection "$(get_connection_from_file /etc/nova/nova-cell0.conf)"
fi
if [ "${found_cell1}" = "false" ]; then
  echo "Creating cell1..."
  $nova_manage_api cell_v2 create_cell --verbose \
      --name "cell1" \
      --transport-url "$(get_transport_url_from_file /etc/nova/nova-cell1.conf)" \
      --database_connection "$(get_connection_from_file /etc/nova/nova-cell1.conf)"
  $nova_manage_api cell_v2 discover_hosts
fi

{{ if .Values.cell2.enabled }}
if [ "$found_cell2" = "false" ]; then
  echo "Creating cell2..."
  $nova_manage_api cell_v2 create_cell --verbose \
      --name "{{.Values.cell2.name}}" \
      --transport-url "$(get_transport_url_from_file /etc/nova/nova-{{ .Values.cell2.name }}.conf)" \
      --database_connection "$(get_connection_from_file /etc/nova/nova-{{ .Values.cell2.name }}.conf)"
fi
{{- end }}

echo "Migrating cell0 and cell1"
$nova_manage_cell1 db sync

{{- if .Values.cell2.enabled }}

echo "Migrating cell2"
$nova_manage_cell2 db sync --local_cell
{{- end }}

# online data migration run by online-migration-job

{{ include "utils.script.job_finished_hook" . }}
