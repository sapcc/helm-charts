[DEFAULT]
{{- include "ini_sections.default_transport_url" . }}

{{- include "ini_sections.database" . }}


[neutron]
username = {{ .Values.global.manila_network_username | default "manila-neutron" | include "resolve_secret" | replace "$" "$$"}}
password = {{ .Values.global.manila_network_password | default "" | include "resolve_secret" | replace "$" "$$"}}

[keystone_authtoken]
username = {{ .Values.global.manila_service_username | default "manila" | include "resolve_secret" | replace "$" "$$" }}
password = {{ .Values.global.manila_service_password | default "" | include "resolve_secret" | replace "$" "$$"}}


{{ include "ini_sections.audit_middleware_notifications" . }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
