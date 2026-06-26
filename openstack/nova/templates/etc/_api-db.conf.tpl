[api_database]
connection = {{ include "nova.helpers.db_url" (tuple . "api") }}
{{- include "ini_sections.database_options_mysql" . | indent 0 }}
