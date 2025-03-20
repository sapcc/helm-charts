[placement_database]
{{- if or (eq .Values.dbType "mariadb") (eq .Values.dbType "pxc-db") }}
connection = {{ include "utils.db_url" . }}
{{/* Use nova-api-mariadb database, if no database is selected explicitly */}}
{{- else }}
connection = {{ tuple . .Values.api_db.name .Values.api_db.user .Values.api_db.password | include "utils.db_url" }}
{{- end }}

[keystone_authtoken]
username = {{ .Values.global.placement_service_user | default "placement" | include "resolve_secret" }}
password = {{ required ".Values.global.placement_service_password is missing" .Values.global.placement_service_password | include "resolve_secret" }}
