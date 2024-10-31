# secret.conf
[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[nova]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}

[keystone_authtoken]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
