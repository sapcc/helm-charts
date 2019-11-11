{{- define "oslo_messaging_rabbit" }}
{{- include "ini_sections.oslo_messaging_rabbit" . }}
{{- /* Those options are ignored, if transport_url is set */}}
rabbit_userid = {{ .Values.rabbitmq_user | default .Values.global.rabbitmq_default_user | default "openstack"}}
rabbit_password = {{ .Values.rabbitmq_pass | default .Values.global.rabbitmq_default_pass | default "openstack" }}
rabbit_hosts =  {{ .Chart.Name }}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end }}

{{- define "ini_sections.oslo_messaging_rabbit" }}
[oslo_messaging_rabbit]
rabbit_ha_queues = {{ .Values.rabbitmq_ha_queues | default .Values.global.rabbitmq_ha_queues | default "true" }}
rabbit_transient_queues_ttl = {{ .Values.rabbit_transient_queues_ttl | default .Values.global.rabbit_transient_queues_ttl | default 60 }}
{{- end }}

{{- define "ini_sections.default_transport_url" }}
transport_url = {{ include "rabbitmq.transport_url" . }}
{{- end }}

{{- define "ini_sections.database_options" }}
{{- if or .Values.postgresql.pgbouncer.enabled .Values.global.pgbouncer.enabled }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 10 }}
max_overflow = -1
{{- end }}
{{- end }}

{{- define "ini_sections.database_options_mysql" }}
min_pool_size = {{ .Values.min_pool_size | default .Values.global.min_pool_size | default 10 }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 100 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 50 }}
{{- end }}

{{- define "ini_sections.database" }}

[database]
{{- if eq .Values.postgresql.enabled false }}
connection = {{ include "db_url_mysql" . }}
{{- include "ini_sections.database_options_mysql" . }}
{{- else }}
connection = {{ include "db_url" . }}
{{- include "ini_sections.database_options" . }}
{{- end }}
{{- end }}

{{- define "ini_sections.cache" }}

[cache]
backend = oslo_cache.memcache_pool
{{- if .Values.memcached.host }}
memcache_servers = {{ .Values.memcached.host }}:{{ .Values.memcached.port | default 11211 }}
{{- else }}
memcache_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
{{- end }}
config_prefix = cache.{{ .Chart.Name }}
enabled = true
{{- end }}

{{- define "ini_sections.audit_middleware_notifications"}}
    {{- if .Values.audit }}
        {{- if .Values.audit.enabled }}
            {{- if .Values.rabbitmq_notifications }}
                {{- if and .Values.rabbitmq_notifications.ports .Values.rabbitmq_notifications.users }}

# this is for the cadf audit messaging
[audit_middleware_notifications]
# topics = notifications
driver = messagingv2
transport_url = rabbit://{{ .Values.rabbitmq_notifications.users.default.user }}:{{ .Values.rabbitmq_notifications.users.default.password | default (tuple . .Values.rabbitmq_notifications.users.default.user | include "rabbitmq.password_for_user") | urlquery}}@{{ .Chart.Name }}-rabbitmq-notifications:{{ .Values.rabbitmq_notifications.ports.public }}/
mem_queue_size = {{ .Values.audit.mem_queue_size }}
                {{- end }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}

{{- define "oslo_messaging_rabbit_url" }}rabbit://{{ default "" .Values.global.user_suffix | print (default .Values.global.rabbitmq_default_user .Values.rabbitmq_user) }}:{{ .Values.rabbitmq_pass | default .Values.global.rabbitmq_default_pass | default (tuple . (default .Values.global.rabbitmq_default_user .Values.rabbitmq_user) "rabbitmq" | include "svc.password_for_user_and_service" | urlquery ) }}@{{ include "rabbitmq_host" . }}{{- end }}

{{- define "ini_sections.transport_url" }}rabbit://{{ default "" .Values.global.user_suffix | print (default .Values.global.rabbitmq_default_user .Values.rabbitmq_user) }}:{{ .Values.rabbitmq_pass | default .Values.global.rabbitmq_default_pass | default (tuple . (default .Values.global.rabbitmq_default_user .Values.rabbitmq_user) "rabbitmq" | include "svc.password_for_user_and_service" | urlquery ) }}@{{ include "rabbitmq_host" . }}{{- end }}
