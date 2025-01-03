[database]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
connection = {{ include "db_url_pxc" . }}
{{- else if .Values.dbType }}
connection = {{ include "utils.db_url" . }}
{{- else }}
connection = {{ include "db_url_mysql" . }}
{{- end }}

{{- if and .Values.memcached.auth.username .Values.memcached.auth.password }}
[cache]
memcache_sasl_enabled = True
memcache_username = {{ .Values.memcached.auth.username }}
memcache_password = {{ .Values.memcached.auth.password }}
{{- end }}

{{- if not (and (hasKey $.Values "oslo_messaging_notifications") ($.Values.oslo_messaging_notifications.disabled)) }}
[oslo_messaging_notifications]
driver = messaging
  {{- if and (.Values.audit.central_service.user) (.Values.audit.central_service.password) }}
transport_url = rabbit://{{ .Values.audit.central_service.user }}:{{ .Values.audit.central_service.password }}@{{ .Values.audit.central_service.host }}:{{ .Values.audit.central_service.port }}/

[oslo_messaging_rabbit]
rabbit_retry_interval = {{ .Values.audit.central_service.rabbit_retry_interval | default 1 }}
kombu_reconnect_delay = {{ .Values.audit.central_service.kombu_reconnect_delay | default 0.1 }}
rabbit_interval_max = {{ .Values.audit.central_service.rabbit_interval_max | default 1 }}
rabbit_retry_backoff = {{ .Values.audit.central_service.rabbit_retry_backoff | default 0 }}
heartbeat_timeout_threshold = {{ .Values.audit.central_service.heartbeat_timeout_threshold | default 0 }}
{{/* The default values cause a one second delay
      on the first try and a 0.1 second on all the other ones.
      It is exploiting a bug in the logic which seems to be triggered
      when rabbit_interval_max >= rabbit_retry_interval
*/}}
  {{- else if .Values.rabbitmq.host }}
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}:{{ .Values.rabbitmq.users.default.password }}@{{ .Values.rabbitmq.host }}:{{ .Values.rabbitmq.port | default 5672 }}
  {{ else }}
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}:{{ .Values.rabbitmq.users.default.password }}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.port | default 5672 }}
  {{- end }}
{{- end }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
