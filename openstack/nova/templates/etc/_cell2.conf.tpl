[DEFAULT]
transport_url = {{ include "nova.helpers.cell_rabbitmq_url" (tuple . "cell2") }}

[database]
connection = {{ include "nova.helpers.db_url" (tuple . "cell2") }}
