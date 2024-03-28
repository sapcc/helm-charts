[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[database]
connection = {{ include "db_url_mysql" . }}
