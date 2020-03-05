{{- if .Values.imageVersionGlanceRegistry }}
[DEFAULT]
debug = {{.Values.registry.debug}}

log_config_append = /etc/glance/logging.ini

#disable default admin rights for role 'admin'
admin_role = ''

rpc_response_timeout = {{ .Values.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default 100 }}

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
password = {{ .Values.global.glance_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
insecure = True
token_cache_time = 600
include_service_catalog = false
service_token_roles_required = True

[paste_deploy]
flavor = keystone

[oslo_messaging_notifications]
driver = noop

 {{- if .Values.audit.enabled }}
# Defines CADF Audit Middleware section
[audit_middleware_notifications]
topics = notifications
driver = messagingv2
transport_url = rabbit://rabbitmq:{{ .Values.rabbitmq_notifications.users.default.password }}@glance-rabbitmq-notifications:5672/
mem_queue_size = 1000
{{- end }}

{{- include "ini_sections.cache" . }}


{{- end }}
