[oslo_messaging_amqp]
{{- include "ini_sections.default_transport_url" . }}

[database]
connection = {{ include "utils.db_url" . }}

[keystone_authtoken]
username = masakari
password = {{ .Values.global.masakari_service_password }}

[taskflow]
connection = {{ include "utils.db_url" . }}
