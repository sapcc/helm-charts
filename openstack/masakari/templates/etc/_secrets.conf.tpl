[oslo_messaging_amqp]
{{- include "ini_sections.default_transport_url" . }}

[database]
connection = {{ .Values.sqlite.connection }}

[keystone_authtoken]
username = masakari
password = {{ .Values.global.masakari_service_password }}

[taskflow]
connection = {{ .Values.sqlite.connection }}
