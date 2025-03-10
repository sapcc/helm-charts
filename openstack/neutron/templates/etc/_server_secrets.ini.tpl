[nova]
username = {{ .Values.global.neutron_service_user | default "neutron" | include "resolve_secret" }}
password = {{ .Values.global.neutron_service_password | default "" | include "resolve_secret" }}

[designate]
username = {{ .Values.global.neutron_service_user | default "neutron" | include "resolve_secret" }}
password = {{ .Values.global.neutron_service_password | default "" | include "resolve_secret" }}

[database]
connection = {{ include "utils.db_url" . }}

{{- include "ini_sections.audit_middleware_notifications" . }}
