[placement_database]
connection = {{ include "utils.db_url" . }}

[keystone_authtoken]
username = {{ .Values.global.placement_service_user | default "placement" | include "resolve_secret" }}
password = {{ required ".Values.global.placement_service_password is missing" .Values.global.placement_service_password | include "resolve_secret" }}

{{- include "osprofiler" . }}
