[DEFAULT]
# Print debugging output (set logging level to DEBUG instead of default WARNING level).
debug = True

# AMQP Transport URL
{{ include "ini_sections.default_transport_url" . }}

[api_settings]
bind_host = 0.0.0.0
bind_port = {{.Values.global.octavia_port_internal | default 9876}}

# How should authentication be handled (keystone, noauth)
auth_strategy = keystone

# Dictionary of enabled provider driver names and descriptions
enabled_provider_drivers = noop_driver: 'The No-Op driver.'

# Default provider driver
default_provider_driver = noop_driver

[database]
connection = {{ include "db_url_mysql" . }}

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Release.Name }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.octavia_service_password | default (tuple . .Release.Name | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_id = default
project_name = service
project_domain_id = default
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
service_token_roles_required = True
token_cache_time = 600
include_service_catalog = false

[controller_worker]
# Amphora driver options are amphora_noop_driver,
#                            amphora_haproxy_rest_driver
#
amphora_driver = amphora_noop_driver

# Compute driver options are compute_noop_driver
#                            compute_nova_driver
#
compute_driver = compute_noop_driver

# Network driver options are network_noop_driver
#                            allowed_address_pairs_driver
#
network_driver = network_noop_driver

{{- include "ini_sections.cache" . }}
