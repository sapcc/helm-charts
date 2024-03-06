[DEFAULT]
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}:{{ .Values.rabbitmq.users.default.password }}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.port | default 5672 }}/

[keystone_authtoken]
username = {{ .Values.global.designate_service_user | default "designate" }}
password = {{ .Values.global.designate_service_password }}

[storage:sqlalchemy]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ if .Values.percona_cluster.enabled -}}
connection = {{ include "db_url_pxc" . }}
{{- else }}
connection = {{ include "db_url_mysql" . }}
{{- end }}

{{ include "ini_sections.audit_middleware_notifications" . }}
