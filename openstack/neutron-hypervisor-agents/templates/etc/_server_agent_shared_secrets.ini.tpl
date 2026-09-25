[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Values.global.neutron_service_user | default "neutron" | include "resolve_secret" }}
password = {{ .Values.global.neutron_service_password | default "" | include "resolve_secret" }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
