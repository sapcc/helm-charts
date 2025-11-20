[DEFAULT]
transport_url = {{ include "cell1_transport_url" . }}

[database]
connection = {{ include "cell1_db_path" . }}
