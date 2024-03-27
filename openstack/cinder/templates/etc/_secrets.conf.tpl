[DEFAULT]
{{- template "ini_sections.default_transport_url" . }}

{{- include "ini_sections.database" . }}

{{- include "osprofiler" . }}

[keystone_authtoken]
username = {{ .Values.global.cinder_service_user | default "cinder"}}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password | replace "$" "$$" }}

[service_user]
username = {{ .Values.global.cinder_service_user | default "cinder" }}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password }}

[nova]
username = {{ .Values.global.cinder_service_user | default "cinder" }}
password = {{ required ".Values.global.cinder_service_password is missing" .Values.global.cinder_service_password }}

{{- include "ini_sections.audit_middleware_notifications" . }}
