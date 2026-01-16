[DEFAULT]
transport_url = {{ include "cell1_transport_url" . }}

[database]
connection = {{ include "nova.helpers.db_url" (tuple . "cell1") }}
