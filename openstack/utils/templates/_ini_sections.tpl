{{- define "ini_sections.oslo_messaging_rabbit" }}
[oslo_messaging_rabbit]
rabbit_ha_queues = {{ .Values.rabbitmq_ha_queues | default .Values.global.rabbitmq_ha_queues | default "true" }}
rabbit_transient_queues_ttl = {{ .Values.rabbit_transient_queues_ttl | default .Values.global.rabbit_transient_queues_ttl | default 60 }}
heartbeat_in_pthread = False
{{- end }}

{{- define "ini_sections.default_transport_url" }}
transport_url = {{ include "rabbitmq.transport_url" . }}
{{- end }}

{{- define "ini_sections.database_options_mysql" }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 50 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 5 }}
{{- end }}

{{- define "ini_sections.database" }}

[database]
{{- if not .Values.postgresql }}
connection = {{ include "db_url_mysql" . }}
{{- else if not .Values.postgresql.enabled }}
connection = {{ include "db_url_mysql" . }}
{{- include "ini_sections.database_options_mysql" . }}
{{- else }}
connection = {{ include "db_url" . }}
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

# this is for the cadf audit messaging
[audit_middleware_notifications]
# topics = notifications
driver = messagingv2
            {{- if .Values.audit.central_service }}
transport_url = rabbit://{{ .Values.audit.central_service.user | required "Please set audit.central_service.user" }}:{{ .Values.audit.central_service.password | required "Please set audit.central_service.password" }}@{{ .Values.audit.central_service.host | default "hermes-rabbitmq-notifications.hermes" }}:{{.Values.audit.central_service.port | default 5672 }}/
            {{- else if .Values.rabbitmq_notifications }}
                {{- if and .Values.rabbitmq_notifications.ports .Values.rabbitmq_notifications.users }}
transport_url = rabbit://{{ .Values.rabbitmq_notifications.users.default.user }}:{{ required ".Values.rabbitmq_notifications.users.default.password missing" .Values.rabbitmq_notifications.users.default.password }}@{{ .Chart.Name }}-rabbitmq-notifications:{{ .Values.rabbitmq_notifications.ports.public }}/
                {{- end }}
            {{- end }}
mem_queue_size = {{ .Values.audit.mem_queue_size }}
        {{- end }}
    {{- end }}
{{- end }}

{{- define "ini_sections.logging_format"}}
logging_context_format_string = %(asctime)s %(process)d %(levelname)s %(name)s [%(request_id)s g%(global_request_id)s %(user_identity)s] %(resource)s%(instance)s%(message)s
logging_default_format_string = %(asctime)s %(process)d %(levelname)s %(name)s [-] %(resource)s%(instance)s%(message)s
logging_user_identity_format = %(user)s %(tenant)s %(domain)s %(user_domain)s %(project_domain)s
logging_exception_prefix = %(asctime)s %(process)d ERROR %(name)s %(resource)s%(instance)s
{{- end }}

{{- define "ini_sections.coordination" -}}
[coordination]
backend_url = {{ if eq .Values.coordinationBackend "memcached" -}}
    memcached://{{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
{{- else if eq .Values.coordinationBackend "file" -}}
    file://$state_path/coordination
{{- else }}
    {{ fail ".Values.coordinationBackend needs to be either \"memcached\" or \"file\"" }}
{{- end }}
{{- end }}
