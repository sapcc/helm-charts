# neutron.conf
[DEFAULT]
verbose = True

log_config_append = /etc/neutron/logging.ini
{{- include "ini_sections.logging_format" . }}

max_allowed_address_pair = {{.Values.max_allowed_address_pair | default 50}}
max_routes = {{.Values.max_routes | default 256}}

allow_overlapping_ips = true
core_plugin = ml2

filter_validation = false

global_physnet_mtu = {{.Values.global.default_mtu | default 9000}}
advertise_mtu = True

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers }}
rpc_state_report_workers = {{ .Values.rpc_state_workers }}

periodic_fuzzy_delay = 10

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "neutron" }}

[nova]
auth_url = {{ .Values.identity_service_url }}
# DEPRECATED: auth_plugin
auth_plugin = v3password
auth_type = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
insecure = True
endpoint_type = internal

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

{{include "ini_sections.oslo_messaging_rabbit" .}}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}

[oslo_middleware]
enable_proxy_headers_parsing = true

[agent]
{{ if .Values.agent.rootwrap_daemon }}
root_helper = sudo
root_helper_daemon = neutron-rootwrap-daemon /etc/neutron/rootwrap.conf
{{ else }}
root_helper = neutron-rootwrap /etc/neutron/rootwrap.conf
{{ end }}

[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = {{ .Values.identity_service_url }}
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
service_token_roles_required = True
insecure = True
token_cache_time = 600
memcache_use_advanced_pool = True
include_service_catalog = true
service_type = network

[oslo_messaging_notifications]
driver = noop

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
[quotas]
default_quota = 0
quota_floatingip = 0
quota_network = 0
quota_subnet = 0
quota_port = 0
quota_router = 0
quota_rbac_policy = 0
# need 1 secgroup quota for "default" secgroup
quota_security_group = 1
# need 4 secgrouprule quota for "default" secgroup
quota_security_group_rule = 4

[privsep]
# The number of threads available for privsep to concurrently run processes.
# Defaults to the number of CPU cores in the system (integer value)
# Minimum value: 1
thread_pool_size = 3

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
