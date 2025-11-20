[api_database]
connection = {{ include "api_db_path" . }}
{{- include "ini_sections.database_options_mysql" . | indent 0 }}
