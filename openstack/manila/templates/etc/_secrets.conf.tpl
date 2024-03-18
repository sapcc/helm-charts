[DEFAULT]
transport_url = {{ include "rabbitmq.transport_url" . }}

{{- include "ini_sections.database" . }}


[neutron]
username = {{ .Values.global.manila_network_username | default "manila-neutron" | replace "$" "$$"}}
password = {{ .Values.global.manila_network_password | default "" | replace "$" "$$"}}

[keystone_authtoken]
username = {{ .Values.global.manila_service_username | default "manila" | replace "$" "$$" }}
password = {{ .Values.global.manila_service_password | default "" | replace "$" "$$"}}


{{ include "ini_sections.audit_middleware_notifications" . }}
