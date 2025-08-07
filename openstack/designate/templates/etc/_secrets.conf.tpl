[DEFAULT]
{{- template "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Values.global.designate_service_user | default "designate" }}
password = {{ .Values.global.designate_service_password | include "resolve_secret" }}
{{- if and .Values.memcached.auth.username .Values.memcached.auth.password }}
memcache_sasl_enabled = True
memcache_username = {{ .Values.memcached.auth.username }}
memcache_password = {{ .Values.memcached.auth.password | include "resolve_secret" }}
{{- end }}

[storage:sqlalchemy]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ include "designate.db_url" . }}

{{ include "ini_sections.audit_middleware_notifications" . }}

# Tracing
{{- include "osprofiler" . }}
