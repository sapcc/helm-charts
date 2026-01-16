[DEFAULT]
transport_url = {{ include "cell2_transport_url" . }}

[database]
connection = {{ include "nova.helpers.db_url" (tuple . "cell2") }}
