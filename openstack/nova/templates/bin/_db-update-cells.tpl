#!/bin/bash

set -e

IFS=$'\n'
found_cell2="false"
for line in $(nova-manage cell_v2 list_cells --verbose | grep 'rabbit://'); do
  cell_name=$(echo "$line" | cut -d'|' -f2 | tr -d '[:space:]')
  cell_uuid=$(echo "$line" | cut -d'|' -f3 | tr -d '[:space:]')
  transport_url=$(echo "$line" | cut -d'|' -f4 | tr -d '[:space:]')
  database_connection=$(echo "$line" | cut -d'|' -f5 | tr -d '[:space:]')
  echo "Processing Cell $cell_uuid"

  if [ "$cell_name" = "None" ]; then
    echo "Renaming default cell to cell1"
    nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --name "cell1"
    cell_name=cell1
  fi

  if [ "$cell_name" = "cell1" ]; then
    if [ "$transport_url" != "{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}" ]; then
      echo "Updating $cell_name transport-url..."
      nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --transport-url "{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}" --database_connection "{{ include "db_url" . }}"
    fi
    if [ "$database_connection" != "{{ include "db_url" . }}" ]; then
      echo "Updating $cell_name database_connection..."
      nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --transport-url "{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}" --database_connection "{{ include "db_url" . }}"
    fi
  fi

{{ if .Values.cell2.enabled }}
  if [ "$cell_name" = "{{.Values.cell2.name}}" ]; then
    found_cell2="true"
    echo "Found existing cell2..."
    if [ "$transport_url" != "{{ include "cell2_transport_url" . }}" ]; then
      echo "Updating $cell_name transport-url..."
      nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --transport-url "{{ include "cell2_transport_url" . }}" --database_connection "{{ include "cell2_db_path" . }}"
    fi
    if [ "$database_connection" != "" ]; then
      echo "Updating $cell_name database_connection..."
      nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --transport-url "{{ include "cell2_transport_url" . }}" --database_connection "{{ include "cell2_db_path" . }}"
    fi
  fi
{{- end }}
done

{{ if .Values.cell2.enabled }}
if [ "$found_cell2" = "false" ]; then
  echo "Creating cell2"
  nova-manage cell_v2 create_cell --name "{{.Values.cell2.name}}" --transport-url "{{ include "cell2_transport_url" . }}" --database_connection "{{ include "cell2_db_path" . }}" --verbose
fi
{{- end }}




exit
