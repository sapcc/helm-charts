# nova-cell2.conf

[DEFAULT]
transport_url = {{ include "cell2_transport_url" . }}

{{- include "nova.helpers.ini_sections.api_database" . }}

[database]
connection = {{ include "cell2_db_path" . }}
