[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
