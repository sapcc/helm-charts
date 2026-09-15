[DEFAULT]
{{- template "ini_sections.default_transport_url" . }}

{{- include "ini_sections.database" . }}

{{- include "osprofiler" . }}

[keystone_authtoken]
username = {{ .Values.global.cinder_service_user | default "cinder" | include "resolve_secret" }}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password | replace "$" "$$" | include "resolve_secret" }}

[service_user]
username = {{ .Values.global.cinder_service_user | default "cinder" | include "resolve_secret" }}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password | include "resolve_secret" }}

[nova]
username = {{ .Values.global.cinder_service_user | default "cinder" | include "resolve_secret" }}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password | include "resolve_secret" }}

{{- include "ini_sections.audit_middleware_notifications" . }}
