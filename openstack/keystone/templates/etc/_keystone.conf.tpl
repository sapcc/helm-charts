[DEFAULT]
debug = {{.Values.debug}}
insecure_debug = true
verbose = true

max_token_size = {{ .Values.api.token.max_token_size | default 255 }}

log_config_append = /etc/keystone/logging.conf
logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s
logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s

notification_format = {{ .Values.api.notifications.format | default "cadf" | quote }}
{{ range $message_type := .Values.api.notifications.opt_out }}
notification_opt_out = {{ $message_type }}
{{ end }}

{{- if .Values.api.auth }}
[auth]
methods = {{ .Values.api.auth.methods | default "password,token" }}
{{ if .Values.api.auth.external }}external = {{ .Values.api.auth.external }}{{ end }}
{{ if .Values.api.auth.password }}password = {{ .Values.api.auth.password }}{{ end }}
{{ if .Values.api.auth.totp }}totp = {{ .Values.api.auth.totp }}{{ end }}
{{- end }}


{{ if .Values.api.cc_x509 }}
[cc_x509]
trusted_issuer_cn = {{ .Values.api.cc_x509.trusted_issuer_cn | default "SSO_CA" }}
trusted_issuer_o = {{ .Values.api.cc_x509.trusted_issuer_o | default "SAP-AG" }}
user_domain_id_header = {{ .Values.api.cc_x509.user_domain_id_header | default "HTTP_X_USER_DOMAIN_ID" }}
user_domain_name_header = {{ .Values.api.cc_x509.user_domain_name_header | default "HTTP_X_USER_DOMAIN_NAME" }}
{{- end }}

{{ if .Values.api.cc_external }}
[cc_external]
user_name_header = {{ .Values.api.cc_external.user_name_header | default "HTTP_X_USER_NAME" }}
user_domain_name_header = {{ .Values.api.cc_external.user_domain_name_header | default "HTTP_X_USER_DOMAIN_NAME" }}
{{- if .Values.api.cc_external.trusted_key }}
trusted_key_header = {{ .Values.api.cc_external.trusted_key_header | default "HTTP_X_TRUSTED_KEY" }}
trusted_key_value = {{ .Values.api.cc_external.trusted_key_value }}
{{- end }}
{{- end }}

{{ if .Values.api.cc_radius }}
[cc_radius]
host = {{ .Values.api.cc_radius.host | default "radius" }}
port = {{ .Values.api.cc_radius.port | default "radius" }}
secret = {{ .Values.api.cc_radius.secret }}
{{ end }}

{{- if .Values.services.ingress.x509.trusted_issuer }}
[tokenless_auth]
trusted_issuer = {{ .Values.services.ingress.x509.trusted_issuer }}
issuer_attribute = {{ .Values.services.ingress.x509.issuer_attribute | default "SSL_CLIENT_I_DN" }}
protocol = x509
{{- end }}

{{ if .Values.api.oauth1 }}
[oauth1]
request_token_duration = {{ .Values.api.oauth1.request_token_duration | default "28800" }}
access_token_duration = {{ .Values.api.oauth1.access_token_duration | default "0" }}
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

# Directory containing Fernet keys used to encrypt and decrypt credentials
# stored in the credential backend. Fernet keys used to encrypt credentials
# have no relationship to Fernet keys used to encrypt Fernet tokens. Both sets
# of keys should be managed separately and require different rotation policies.
# Do not share this repository with the repository used to manage keys for
# Fernet tokens. (string value)
[credential]
key_repository = /credential-keys

[token]
provider = {{ .Values.api.token.provider | default "fernet" }}
expiration = {{ .Values.api.token.expiration | default 3600 }}
{{- if not (eq .Values.release "newton") }}
allow_expired_window = {{ .Values.api.token.allow_expired_window | default 28800 }}
{{- end }}
cache_on_issue = true

[fernet_tokens]
key_repository = /fernet-keys
max_active_keys = {{ .Values.api.fernet.maxActiveKeys | default 3 }}

[database]
connection = postgresql://{{ default .Release.Name .Values.global.dbUser }}:{{ .Values.global.dbPassword }}@{{include "db_host" .}}:5432/{{ default .Release.Name .Values.postgresql.postgresDatabase}}

[assignment]
driver = sql

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
project_name_url_safe = new
domain_name_url_safe = new

[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}
rabbit_password = {{ .Values.rabbitmq.users.default.password }}
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

[oslo_middleware]
enable_proxy_headers_parsing = true
