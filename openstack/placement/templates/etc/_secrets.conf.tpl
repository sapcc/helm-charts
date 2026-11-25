[placement_database]
connection = {{ include "placement.helpers.db_url" . }}

[keystone_authtoken]
username = {{ include "placement.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "placement.helpers.default_service_user_password" . | include "resolve_secret" }}

{{- include "osprofiler" . }}
