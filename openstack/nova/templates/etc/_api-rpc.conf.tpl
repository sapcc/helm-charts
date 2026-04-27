[DEFAULT]
transport_url = {{ include "nova.helpers.cell_rabbitmq_url" (tuple . "cell1") }}
