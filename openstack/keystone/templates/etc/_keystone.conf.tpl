[DEFAULT]
debug = {{.Values.debug}}
insecure_debug = true
verbose = true

log_config_append = /etc/keystone/logging.conf

logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s
logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s

notification_format = {{ .Values.api.notifications.format | default "basic" | quote }}
{{ range $message_type := .Values.api.notifications.opt_out }}
notification_opt_out = {{ $message_type }}
{{ end }}

{{- if .Values.api.auth }}
[auth]
methods = {{ .Values.api.auth.methods | default "password,token" }}
{{ if .Values.api.auth.password }}password = {{ .Values.api.auth.password }}{{ end }}
{{ if .Values.api.auth.totp }}totp = {{ .Values.api.auth.totp }}{{ end }}
{{- end }}

{{- if .Values.services.ingress.x509.trusted_issuer }}
[tokenless_auth]
trusted_issuer = {{ .Values.services.ingress.x509.trusted_issuer }}
issuer_attribute = {{ .Values.services.ingress.x509.issuer_attribute | default "SSL_CLIENT_I_DN" }}
protocol = x509
{{- end }}

[cache]
backend = oslo_cache.memcache_pool
{{- if .Values.memcached.host }}
memcache_servers = {{ .Values.memcached.host }}:{{.Values.memcached.port | default 11211}}
{{ else }}
memcache_servers = {{ include "memcached_host" . }}:{{.Values.memcached.port | default 11211}}
{{- end }}
config_prefix = cache.keystone
enabled = true

[memcache]
{{- if .Values.memcached.host }}
servers = {{ .Values.memcached.host }}:{{.Values.memcached.port | default 11211}}
{{ else }}
servers = {{ include "memcached_host" . }}:{{.Values.memcached.port | default 11211}}
{{- end }}

[token]
provider = {{ .Values.api.token.provider | default "fernet" }}
expiration = {{ .Values.api.token.expiration | default 3600 }}

[fernet_tokens]
key_repository = /fernet-keys
max_active_keys = {{ .Values.api.fernet.maxActiveKeys | default 3 }}

[database]
connection = postgresql://{{ default .Release.Name .Values.postgresql.dbUser }}:{{ .Values.postgresql.dbPassword }}@{{include "db_host" .}}:5432/{{ default .Release.Name .Values.postgresql.postgresDatabase}}

[identity]
default_domain_id = default
domain_specific_drivers_enabled = true
domain_configurations_from_database = true

[trust]
enabled = true
allow_redelegation = true

[resource]
admin_project_domain_name = {{ default "Default" .Values.api.cloudAdminDomainName }}
admin_project_name = {{ default "admin" .Values.api.cloudAdminProjectName }}

[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.rabbitmq.user | default "rabbitmq" }}
rabbit_password = {{ .Values.rabbitmq.password }}
{{- if .Values.rabbitmq.host }}
rabbit_host = {{ .Values.rabbitmq.host }}
{{ else }}
rabbit_host = {{ include "rabbitmq_host" . }}
{{- end }}
rabbit_port = {{ .Values.rabbitmq.port | default 5672 }}
rabbit_virtual_host = {{ .Values.rabbitmq.virtual_host | default "/" }}
rabbit_ha_queues = {{ .Values.rabbitmq.ha_queues | default "false" }}

[oslo_messaging_notifications]
driver = messaging

{{ if .Values.api.radius }}
[radius]
host = {{ .Values.api.radius.host | default "radius" }}
port = {{ .Values.api.radius.port | default "radius" }}
secret = {{ .Values.api.radius.secret }}
{{ end }}