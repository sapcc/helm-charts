#!/bin/bash

set -e


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
    nova-manage cell_v2 update_cell \
        --cell_uuid ${cell_uuid} \
        --transport-url "${wanted_transport_url}" \
        --database_connection "${wanted_database_connection}"
  fi
}


IFS=$'\n'
found_cell0="false"
found_cell1="false"
found_cell2="false"
for line in $(nova-manage cell_v2 list_cells --verbose | grep ':/'); do
  cell_name=$(echo "$line" | cut -d'|' -f2 | tr -d '[:space:]')
  cell_uuid=$(echo "$line" | cut -d'|' -f3 | tr -d '[:space:]')
  transport_url=$(echo "$line" | cut -d'|' -f4 | tr -d '[:space:]')
  database_connection=$(echo "$line" | cut -d'|' -f5 | tr -d '[:space:]')
  echo "Processing Cell $cell_uuid"

  if [ "${cell_name}" = "None" ]; then
    echo "Renaming default cell to cell1"
    nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --name "cell1"
    cell_name="cell1"
  fi

  case "${cell_name}" in
    cell0)
      found_cell0="true"
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "none:/" \
            "${database_connection}" "{{ include "cell0_db_path" . }}"
      ;;
    cell1)
      found_cell1="true"
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}" \
            "${database_connection}" "{{ include "db_url" . }}"
      ;;
{{ if .Values.cell2.enabled }}
    {{.Values.cell2.name}})
      found_cell2="true"
      echo "Found existing cell2..."
      update_cell "${cell_name}" "${cell_uuid}" \
            "${transport_url}" "{{ include "cell2_transport_url" . }}" \
            "${database_connection}" "{{ include "cell2_db_path" . }}"
      ;;
{{- end }}
  esac
done

if [ "${found_cell0}" = "false" ]; then
  echo "Creating cell0..."
  nova-manage cell_v2 map_cell0 \
      --database_connection "{{ include "cell0_db_path" . }}"
fi
if [ "${found_cell1}" = "false" ]; then
  echo "Creating cell1..."
  nova-manage cell_v2 create_cell --verbose \
      --name "cell1" \
      --transport-url "{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}" \
      --database_connection "{{ include "db_url" . }}"
  nova-manage cell_v2 discover_hosts
fi

{{ if .Values.cell2.enabled }}
if [ "$found_cell2" = "false" ]; then
  echo "Creating cell2..."
  nova-manage cell_v2 create_cell --verbose \
      --name "{{.Values.cell2.name}}" \
      --transport-url "{{ include "cell2_transport_url" . }}" \
      --database_connection "{{ include "cell2_db_path" . }}"
fi
{{- end }}

exit
