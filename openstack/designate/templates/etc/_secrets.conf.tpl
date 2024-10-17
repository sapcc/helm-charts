[DEFAULT]
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" | include "resolve_secret_urlquery" }}:{{ .Values.rabbitmq.users.default.password | include "resolve_secret_urlquery" }}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.port | default 5672 }}/

[keystone_authtoken]
username = {{ .Values.global.designate_service_user | default "designate" }}
password = {{ .Values.global.designate_service_password | include "resolve_secret" }}

[storage:sqlalchemy]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ include "designate.db_url" . }}

{{ include "ini_sections.audit_middleware_notifications" . }}
