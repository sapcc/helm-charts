[DEFAULT]
debug = {{.Values.debug}}
insecure_debug = {{.Values.insecure_debug}}
verbose = true

max_token_size = {{ .Values.api.token.max_token_size | default 255 }}

log_config_append = /etc/keystone/logging.conf
logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s
logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s
logging_user_identity_format = usr %(user)s prj %(tenant)s dom %(domain)s usr-dom %(user_domain)s prj-dom %(project_domain)s

notification_format = {{ .Values.api.notifications.format | default "cadf" | quote }}
{{ range $message_type := .Values.api.notifications.opt_out }}
notification_opt_out = {{ $message_type }}
{{ end }}

{{- if .Values.api.auth }}
[auth]
methods = {{ .Values.api.auth.methods | default "password,token,application_credential" }}
{{ if .Values.api.auth.external }}external = {{ .Values.api.auth.external }}{{ end }}
{{ if .Values.api.auth.password }}password = {{ .Values.api.auth.password }}{{ end }}
{{ if .Values.api.auth.totp }}totp = {{ .Values.api.auth.totp }}{{ end }}
{{- end }}

[cc_x509]
trusted_issuer = CN=SSO_CA,O=SAP-AG,C=DE
trusted_issuer = CN=SAP SSO CA G2,O=SAP SE,L=Walldorf,C=DE
user_domain_id_header: HTTP_X_USER_DOMAIN_ID
user_domain_name_header: HTTP_X_USER_DOMAIN_NAME

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
backend = dogpile.cache.memcached
{{- if .Values.memcached.host }}
memcache_servers = {{ .Values.memcached.host }}:{{.Values.memcached.port | default 11211}}
{{ else }}
memcache_servers = {{ include "memcached_host" . }}:{{.Values.memcached.port | default 11211}}
{{- end }}
config_prefix = cache.keystone
expiration_time = {{ .Values.cache.expiration_time | default 600 }}
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
allow_expired_window = {{ .Values.api.token.allow_expired_window | default 28800 }}
cache_on_issue = true
cache_time = {{ .Values.api.token.cache_time | default 1800 }}

[revoke]
expiration_buffer = 3600

[fernet_tokens]
key_repository = /fernet-keys
max_active_keys = {{ .Values.api.fernet.maxActiveKeys | default 3 }}

{{- if eq .Values.release "stein" }}
[fernet_receipts]
key_repository = /fernet-keys
max_active_keys = {{ .Values.api.fernet.maxActiveKeys | default 3 }}
{{- end }}

{{- if eq .Values.release "stein" }}
[access_rules_config]
rules_file = /etc/keystone/access_rules.json
permissive = true
{{- end }}

[database]
connection = mysql+pymysql://{{ default .Release.Name .Values.global.dbUser }}:{{.Values.global.dbPassword }}@{{include "db_host" .}}/{{ default .Release.Name .Values.mariadb.name }}?charset=utf8

[assignment]
driver = sql

[identity]
list_limit = {{ .Values.api.identity.list_limit | default 0 }}
default_domain_id = default
domain_specific_drivers_enabled = true
domain_configurations_from_database = true

[trust]
allow_redelegation = true

[resource]
admin_project_domain_name = {{ default "Default" .Values.api.cloudAdminDomainName }}
admin_project_name = {{ default "admin" .Values.api.cloudAdminProjectName }}
bootstrap_project_domain_name = Default
bootstrap_project_name = admin
project_name_url_safe = new
domain_name_url_safe = new

[security_compliance]
lockout_failure_attempts = 5
lockout_duration = 300
unique_last_password_count = 5

{{- if eq .Values.release "rocky" }}
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
{{- end }}

[oslo_messaging_notifications]
{{- if ne .Values.release "rocky" }}
{{- if .Values.rabbitmq.host }}
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}:{{ .Values.rabbitmq.users.default.password }}@{{ .Values.rabbitmq.host }}:{{ .Values.rabbitmq.port | default 5672 }}
{{ else }}
transport_url = rabbit://{{ .Values.rabbitmq.users.default.user | default "rabbitmq" }}:{{ .Values.rabbitmq.users.default.password }}@{{ include "rabbitmq_host" . }}:{{ .Values.rabbitmq.port | default 5672 }}
{{- end }}
{{ else }}
driver = messaging
{{- end }}

[oslo_middleware]
enable_proxy_headers_parsing = true

[lifesaver]
enabled = {{ .Values.lifesaver.enabled }}
{{- if .Values.memcached.host }}
memcached = {{ .Values.memcached.host }}:{{ .Values.memcached.port | default 11211}}
{{ else }}
memcached = {{ include "memcached_host" . }}:{{ .Values.memcached.port | default 11211}}
{{- end }}
domain_whitelist = {{ .Values.lifesaver.domain_whitelist | default "Default, tempest" }}
user_whitelist = {{ .Values.lifesaver.user_whitelist | default "admin, keystone, nova, neutron, cinder, glance, designate, barbican, dashboard, manila, swift" }}
user_blacklist = {{ .Values.lifesaver.user_blacklist | default "" }}
# initial user credit
initial_credit = {{ .Values.lifesaver.initial_credit | default 100 }}
# how often do we refill credit
refill_seconds = {{ .Values.lifesaver.refill_seconds | default 60 }}
# and with what amount
refill_amount = {{ .Values.lifesaver.refill_amount | default 1 }}
# cost of each status
status_cost = {{ .Values.lifesaver.status_cost | default "default:1,401:10,403:5,404:0,429:0" }}

{{- if .Values.cors.enabled }}
[cors]
allowed_origin = {{ .Values.cors.allowed_origin | default "*"}}
allow_credentials = true
expose_headers = Content-Type,Cache-Control,Content-Language,Expires,Last-Modified,Pragma,X-Auth-Token,X-Openstack-Request-Id,X-Subject-Token
allow_headers = Content-Type,Cache-Control,Content-Language,Expires,Last-Modified,Pragma,X-Auth-Token,X-Openstack-Request-Id,X-Subject-Token,X-Project-Id,X-Project-Name,X-Project-Domain-Id,X-Project-Domain-Name,X-Domain-Id,X-Domain-Name,X-User-Id,X-User-Name,X-User-Domain-name
{{- end }}
