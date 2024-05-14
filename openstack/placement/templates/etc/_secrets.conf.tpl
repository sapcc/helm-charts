[placement_database]
{{- if not .Values.mariadb.enabled }}
connection = {{ tuple . .Values.api_db.name .Values.api_db.user .Values.api_db.password | include "db_url_mysql" }}
{{- else }}
connection = {{ tuple . .Values.mariadb.name .Values.global.dbUser .Values.global.dbPassword | include "db_url_mysql" }}
{{- end }}

[keystone_authtoken]
username = {{ .Values.global.placement_service_user | default "placement" }}
password = {{ required ".Values.global.placement_service_password is missing" .Values.global.placement_service_password }}
