[database]
# Database connection string - MariaDB for regional setup
# and Percona Cluster for inter-regional setup:
{{ if .Values.percona_cluster.enabled -}}
  {{/* in caase percona is active and we need to switch the connection string to mariadb-galera cluster without removing the percona cluster objects */}}
  {{- if and .Values.mariadb_galera.enabled .Values.databaseKind (eq .Values.databaseKind "galera") -}}
connection = mysql+pymysql://{{ .Values.mariadb_galera.mariadb.users.keystone.username }}:{{.Values.mariadb_galera.mariadb.users.keystone.password | include "resolve_secret_urlquery" }}@{{include "db_host" .}}/{{ .Values.mariadb_galera.mariadb.database_name_to_connect }}?charset=utf8
  {{- else }}
connection = {{ include "db_url_pxc" . }}
  {{- end }}
{{- else if .Values.global.clusterDomain -}}
connection = mysql+pymysql://{{ default .Release.Name .Values.global.dbUser }}:{{.Values.global.dbPassword | include "resolve_secret_urlquery" }}@{{include "db_host" .}}/{{ default .Release.Name .Values.mariadb.name }}?charset=utf8
{{- else if and .Values.mariadb_galera.enabled .Values.databaseKind (eq .Values.databaseKind "galera") -}}
connection = mysql+pymysql://{{ .Values.mariadb_galera.mariadb.users.keystone.username }}:{{.Values.mariadb_galera.mariadb.users.keystone.password | include "resolve_secret_urlquery" }}@{{include "db_host" .}}/{{ .Values.mariadb_galera.mariadb.database_name_to_connect }}?charset=utf8
{{- else }}
connection = {{ include "db_url_mysql" . }}
{{- end }}

{{- if and .Values.memcached.auth.username .Values.memcached.auth.password }}
[cache]
memcache_sasl_enabled = True
memcache_username = {{ .Values.memcached.auth.username }}
memcache_password = {{ .Values.memcached.auth.password | include "resolve_secret" }}
{{- end }}

{{- if not (and (hasKey $.Values "oslo_messaging_notifications") ($.Values.oslo_messaging_notifications.disabled)) }}
[oslo_messaging_notifications]
driver = messaging
  {{- if and (.Values.audit.central_service.user) (.Values.audit.central_service.password) }}
transport_url = rabbit://{{ .Values.audit.central_service.user | include "resolve_secret_urlquery" }}:{{ .Values.audit.central_service.password | include "resolve_secret_urlquery" }}@{{ .Values.audit.central_service.host }}:{{ .Values.audit.central_service.port }}/

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
  {{- end }}
{{- end }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}

{{ if .Values.api.cc_radius }}
[cc_radius]
host = {{ .Values.api.cc_radius.host | default "radius" }}
port = {{ .Values.api.cc_radius.port | default "radius" }}
secret = {{ .Values.api.cc_radius.secret | include "resolve_secret" }}
{{ end }}


{{ if .Values.api.cc_external }}
[cc_external]
user_name_header = {{ .Values.api.cc_external.user_name_header | default "HTTP_X_USER_NAME" }}
user_domain_name_header = {{ .Values.api.cc_external.user_domain_name_header | default "HTTP_X_USER_DOMAIN_NAME" }}
{{- if .Values.api.cc_external.trusted_key }}
trusted_key_header = {{ .Values.api.cc_external.trusted_key_header | default "HTTP_X_TRUSTED_KEY" }}
trusted_key_value = {{ .Values.api.cc_external.trusted_key_value }}
{{- end }}
{{- end }}
