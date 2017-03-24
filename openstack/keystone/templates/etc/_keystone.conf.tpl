[DEFAULT]
debug = {{.Values.debug}}
insecure_debug = true
verbose = true

logging_context_format_string = %(process)d %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s
logging_default_format_string = %(process)d %(levelname)s %(name)s [-] %(instance)s%(message)s
logging_exception_prefix = %(process)d ERROR %(name)s %(instance)s

notification_format = {{ .Values.notifications.format | default "basic" | quote }}
driver = messaging

[cache]
backend = oslo_cache.memcache_pool
memcache_servers = {{include "memcached_host" . | default "memcached" }}:{{.Values.memcached.port | default 11211}}
config_prefix = cache.keystone
enabled = true

[memcache]
servers = {{include "memcached_host" . | default "memcached" }}:{{.Values.memcached.port | default 11211}}

[token]
provider = {{ .Values.token.provider | default "fernet" }}
expiration = {{ .Values.token.expiration | default 3600 }}

[fernet_tokens]
key_repository = /fernet-keys
max_active_keys = {{ .Values.fernet.max_active_keys | default 3 }}

[database]
connection = postgresql://{{ .Values.postgresql.dbUser }}:{{ .Values.postgresql.dbPassword }}@{{include "db_host" .}}:5432/{{.Values.postgresql.postgresDatabase}}

[identity]
default_domain_id = default
domain_specific_drivers_enabled = true
domain_configurations_from_database = true

[trust]
enabled = true
allow_redelegation = true

[resource]
admin_project_domain_name = Default
admin_project_name = admin

[oslo_messaging_rabbit]
rabbit_userid = {{ .Values.rabbitmq.user | default "rabbitmq" }}
rabbit_password = {{ .Values.rabbitmq.password }}
rabbit_host = {{ .Values.rabbitmq.host | default "rabbitmq" }}
rabbit_port = {{ .Values.rabbitmq.port | default 5672 }}
rabbit_virtual_host = {{ .Values.rabbitmq.virtual_host | default "/" }}
rabbit_ha_queues = {{ .Values.rabbitmq.ha_queues | default "false" }}
