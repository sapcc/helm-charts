[DEFAULT]
{{- template "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Values.global.designate_service_user | default "designate" }}
password = {{ .Values.global.designate_service_password | include "resolve_secret" }}

[storage:sqlalchemy]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ include "designate.db_url" . }}

{{ include "ini_sections.audit_middleware_notifications" . }}

# Tracing
{{- include "osprofiler" . }}
