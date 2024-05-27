[DEFAULT]
# Show debugging output in logs (sets DEBUG log level output)
debug = {{.Values.debug}}

log_config_append = /etc/barbican/logging.ini
{{- include "ini_sections.logging_format" . }}

# Address to bind the API server
bind_host = 0.0.0.0

# Port to bind the API server to
bind_port =  {{.Values.global.barbican_port_internal | default 9311}}

# Host name, for use in HATEOAS-style references
#  Note: Typically this would be the load balanced endpoint that clients would use
#  communicate back with this service.
# If a deployment wants to derive host from wsgi request instead then make this
# blank. Blank is needed to override default config value which is
# 'http://localhost:9311'.
host_href = {{.Values.global.barbican_api_endpoint_protocol_public | default "https"}}://{{include "barbican_api_endpoint_host_public" .}}:{{.Values.global.barbican_api_port_public | default 443}}

# Log to this file. Make sure you do not set the same log
# file for both the API and registry servers!
#log_file = /var/log/barbican/api.log

# Backlog requests when creating socket
backlog = 4096

# TCP_KEEPIDLE value in seconds when creating socket.
# Not supported on OS X.
#tcp_keepidle = 600

# Maximum allowed http request size against the barbican-api
max_allowed_secret_in_bytes = 20000
max_allowed_request_size_in_bytes = 1000000

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 10 }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 50 }}

max_limit_paging = 3000

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_id = default
project_name = service
project_domain_id = default
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
service_token_roles_required = True
token_cache_time = 600
include_service_catalog = true
service_type = key-manager

{{- include "ini_sections.cache" . }}

[oslo_policy]
policy_file = /etc/barbican/policy.yaml
enforce_new_defaults=False
enforce_scope=False

{{- if .Values.hsm.multistore.enabled }}
[secretstore]
enable_multiple_secret_stores = True
stores_lookup_suffix = software, pkcs11
namespace = barbican.secretstore.plugin

[secretstore:software]
secret_store_plugin = store_crypto
crypto_plugin = simple_crypto

[secretstore:pkcs11]
secret_store_plugin = store_crypto
crypto_plugin = p11_crypto
global_default = True
{{- end }}
