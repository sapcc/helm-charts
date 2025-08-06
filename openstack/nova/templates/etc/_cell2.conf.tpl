[DEFAULT]
transport_url = {{ include "cell2_transport_url" . }}

[database]
connection = {{ include "cell2_db_path" . }}
