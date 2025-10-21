{{- define "ini_sections.oslo_messaging_rabbit" }}
[oslo_messaging_rabbit]
rabbit_ha_queues = {{ .Values.rabbitmq_ha_queues | default .Values.global.rabbitmq_ha_queues | default "true" }}
rabbit_transient_queues_ttl = {{ .Values.rabbit_transient_queues_ttl | default .Values.global.rabbit_transient_queues_ttl | default 60 }}
heartbeat_in_pthread = False
    {{- if .Values.rabbitmq_ssl_client }}
ssl = {{ .Values.rabbitmq_ssl_client }}
    {{- end }}
{{- end }}

{{- define "ini_sections.default_transport_url" }}
{{- $defaultUser := default "default" .Values.rabbitmq.defaultUser }}
{{- if and (hasKey .Values.global "rabbitmq") (hasKey .Values.global.rabbitmq "defaultUser") (hasKey .Values.rabbitmq "defaultUser") }}
    {{- $defaultUser = coalesce .Values.global.rabbitmq.defaultUser .Values.rabbitmq.defaultUser "default" }}
{{- end }}
{{- $user := index .Values.rabbitmq.users $defaultUser }}
{{- $data := merge (pick .Values.rabbitmq "host" "port" "virtual_host") $user }}
{{- $_ := required (printf ".Values.rabbitmq.users.%s.user is required" $defaultUser) $data.user }}
{{- $_ := required (printf ".Values.rabbitmq.users.%s.password is required" $defaultUser) $data.password }}
{{- include "ini_sections._transport_url" (tuple . $data) }}
{{- end }}

{{- define "ini_sections._transport_url" }}
transport_url = {{ include "utils.rabbitmq_url" . }}
{{- end }}


{{- define "utils.rabbitmq_url" -}}
{{- $envAll := index . 0 -}}
{{- $data := index . 1 -}}
{{- $ssl := dig "rabbitmq_ssl_client" false $envAll.Values.AsMap }}
rabbit://{{ include "resolve_secret_urlquery" $data.user }}:{{ include "resolve_secret_urlquery" $data.password }}@{{ $data.host | default (print $envAll.Release.Name "-rabbitmq") }}:{{ $data.port | default (ternary 5671 5672 $ssl) }}/{{ $data.virtual_host | default "" }}
{{- end -}}

{{- define "ini_sections.database_options_mysql" }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 50 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 5 }}
{{- end }}

{{- define "ini_sections.database" }}

[database]
connection = {{ include "utils.db_url" . }}
{{- include "ini_sections.database_options_mysql" . }}
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
{{ $ssl := dig "rabbitmq_ssl_client" false .Values.AsMap }}
# this is for the cadf audit messaging
[audit_middleware_notifications]
# topics = notifications
driver = messagingv2
            {{- if .Values.audit.central_service }}
                {{- $data := pick .Values.audit.central_service "user" "password" "host" "port" }}
                {{- $_ := required ".Values.audit.central_service.user is required" $data.user }}
                {{- $_ := required ".Values.audit.central_service.password is required" $data.password }}
                {{- $_ := set $data "host" ($data.host | default "hermes-rabbitmq-notifications.hermes") }}
                {{- include "ini_sections._transport_url" (tuple . $data) }}
            {{- else if .Values.rabbitmq_notifications }}
                {{- if and .Values.rabbitmq_notifications.ports .Values.rabbitmq_notifications.users }}
                    {{- $data := dict "user" .Values.rabbitmq_notifications.users.default.user "password" .Values.rabbitmq_notifications.users.default.password "host" (print .Release.Name "-rabbitmq-notifications") "port" (ternary .Values.rabbitmq_notifications.ports.amqps .Values.rabbitmq_notifications.ports.public $ssl)}}
                    {{- $_ := required ".Values.rabbitmq_notifications.users.default.user is required" $data.user }}
                    {{- $_ := required ".Values.rabbitmq_notifications.users.default.password is required" $data.password }}
                    {{- include "ini_sections._transport_url" (tuple . $data) }}
                {{- end }}
            {{- end }}
mem_queue_size = {{ .Values.audit.mem_queue_size | default 1000 | int }}
        {{- end }}
    {{- end }}
{{- end }}

{{- define "ini_sections.logging_format"}}
logging_context_format_string = %(asctime)s %(process)d %(levelname)s %(name)s [%(request_id)s g%(global_request_id)s %(user_identity)s] %(resource)s%(instance)s%(message)s
logging_default_format_string = %(asctime)s %(process)d %(levelname)s %(name)s [-] %(resource)s%(instance)s%(message)s
logging_user_identity_format = %(user)s %(project)s %(domain)s %(system_scope)s %(user_domain)s %(project_domain)s
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
