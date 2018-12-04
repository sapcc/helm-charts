#!/bin/sh

set -x
set -e

# Not yet usable for multiple cells
cells=$(nova-manage cell_v2 list_cells --verbose | grep 'rabbit://')
cell_uuid=$(echo "$cells" | cut -d'|' -f3 | tr -d '[:space:]')
transport_url=$(echo "$cells" | cut -d'|' -f4 | tr -d '[:space:]')
database_connection=$(echo "$cells" | cut -d'|' -f5 | tr -d '[:space:]')

update_cell=false
if [ "$transport_url" != "{{ include "rabbitmq.transport_url" . }}" ]; then
    nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --transport-url "{{ include "rabbitmq.transport_url" . }}"
fi
if [ "$database_connection" != "{{ include "db_url" . }}" ]; then
    nova-manage cell_v2 update_cell --cell_uuid $cell_uuid --database_connection "{{ include "db_url" . }}"
fi
