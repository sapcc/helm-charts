[DEFAULT]
# Print debugging output (set logging level to DEBUG instead of default WARNING level).
debug = {{.Values.debug | default "false" }}
log_config_append = /etc/octavia/logging.ini
{{- include "ini_sections.logging_format" . }}

# Plugin options are hot_plug_plugin (Hot-pluggable controller plugin)
octavia_plugins = f5_plugin

# Tracing
{{- include "osprofiler" . }}

[api_settings]
bind_host = 0.0.0.0
bind_port = {{.Values.global.octavia_port_internal | default 9876}}
healthcheck_enabled = True

# Enable/disable exposing API endpoints. By default, both v1 and v2 are enabled.
api_v1_enabled = False
api_v2_enabled = True

# How should authentication be handled (keystone, noauth)
auth_strategy = keystone

# Dictionary of enabled provider driver names and descriptions
enabled_provider_drivers = {{ .Values.providers }}

# Default provider driver
default_provider_driver = {{ .Values.default_provider | default "noop_driver" }}

# Enable/disable specific features
allow_prometheus_listeners = False

# TLS ciphers
tls_cipher_allow_list = {{ .Values.tls.cipher_suites.allow_list | join ":" }}
default_listener_ciphers = {{ .Values.tls.cipher_suites.default.listeners | join ":" }}
default_pool_ciphers = {{ .Values.tls.cipher_suites.default.pools | join ":" }}

# TLS versions
minimum_tls_version = {{ .Values.tls.versions.minimum }}
default_listener_tls_versions = {{ .Values.tls.versions.default.listeners | join ", " }}
default_pool_tls_versions = {{ .Values.tls.versions.default.pools | join ", " }}

[healthcheck]
backends = octavia_db_check

[controller_worker]
worker = {{ .Values.worker | default 1 }}
amphora_driver = {{ .Values.amphora_driver  | default "amphora_noop_driver" }}
compute_driver = {{ .Values.compute_driver  | default "compute_noop_driver" }}
network_driver = {{ .Values.network_driver  | default "network_noop_driver" }}

{{ if .Values.status_manager }}
[status_manager]
health_check_interval = {{ .Values.status_manager.health_check_interval }}
{{- if .Values.status_manager.health_update_threads }}
health_update_threads = {{ .Values.status_manager.health_update_threads }}
{{- end }}
{{- if .Values.status_manager.stats_update_threads }}
stats_update_threads = {{ .Values.status_manager.stats_update_threads }}
{{- end }}
{{- end }}

{{ if .Values.house_keeping }}
[house_keeping]
cleanup_interval = {{ .Values.house_keeping.cleanup_interval }}
load_balancer_expiry_age = {{ .Values.house_keeping.expiry_age }}
{{- end }}

[networking]
caching = {{ .Values.caching | default "true" }}
cache_time = {{ .Values.cache_time | default "90" }}
{{ if .Values.network_segment_physical_network }}
f5_network_segment_physical_network = {{ .Values.network_segment_physical_network }}
{{- end }}

[task_flow]
max_workers = {{ .Values.max_workers | default "10" }}

[database]
max_pool_size = 30
max_overflow = 50

[oslo_messaging]
# Topic (i.e. Queue) Name
topic = f5_prov

[oslo_middleware]
# HTTPProxyToWSGI middleware enabled
enable_proxy_headers_parsing = true

[certificates]
endpoint_type = internal
region_name = {{.Values.global.region}}

[neutron]
endpoint_type = internal
region_name = {{.Values.global.region}}

[service_auth]
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
auth_version = v3
auth_type = v3password
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
project_name = service
project_domain_id = default
user_domain_id = default

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
service_type = load-balancer

{{- include "ini_sections.cache" . }}

{{ if .Values.cors.enabled -}}
[cors]
allowed_origin = {{ .Values.cors.allowed_origin | default "*"}}
allow_credentials = true
expose_headers = Content-Type,Cache-Control,Content-Language,Expires,Last-Modified,Pragma,X-Auth-Token,X-Openstack-Request-Id,X-Subject-Token
allow_headers = Content-Type,Cache-Control,Content-Language,Expires,Last-Modified,Pragma,X-Auth-Token,X-Openstack-Request-Id,X-Subject-Token,X-Project-Id,X-Project-Name,X-Project-Domain-Id,X-Project-Domain-Name,X-Domain-Id,X-Domain-Name,X-User-Id,X-User-Name,X-User-Domain-name
{{- end }}

{{ if .Values.watcher.enabled -}}
[watcher]
enabled = true
service_type = loadbalancer
config_file = /etc/octavia/watcher.yaml
{{- end }}
