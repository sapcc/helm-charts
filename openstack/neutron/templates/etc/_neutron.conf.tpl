# neutron.conf
[DEFAULT]
debug = {{.Values.debug}}
verbose = True

log_config_append = /etc/neutron/logging.conf
api_paste_config = /etc/neutron/api-paste.ini
{{ include "ini_sections.default_transport_url" . }}

pagination_max_limit = 500
max_allowed_address_pair = {{.Values.max_allowed_address_pair | default 50}}
max_routes = {{.Values.max_routes | default 256}}

allow_overlapping_ips = true
core_plugin = ml2

service_plugins = {{required "A valid .Values.service_plugins required!" .Values.service_plugins}}

default_router_type = {{required "A valid .Values.default_router_type required!" .Values.default_router_type}}
router_scheduler_driver = {{required "A valid .Values.router_scheduler_driver required!" .Values.router_scheduler_driver}}
router_auto_schedule = {{ .Values.router_auto_schedule | default "false" }}
allow_automatic_l3agent_failover = {{ .Values.allow_automatic_l3agent_failover | default "false" }}

network_scheduler_driver = neutron.scheduler.dhcp_agent_scheduler.AZAwareWeightScheduler
allow_automatic_dhcp_failover = {{ .Values.allow_automatic_dhcp_failover | default "false" }}
dhcp_agents_per_network = 2
dhcp_lease_duration = {{ .Values.dhcp_lease_duration | default 86400 }}

# Designate configuration
dns_domain = {{required "A valid .Values.dns_local_domain required!" .Values.dns_local_domain}}
{{- if .Values.dns_external_driver }}
external_dns_driver = {{required "A valid .Values.dns_external_driver required!" .Values.dns_external_driver}}
{{- end }}

global_physnet_mtu = {{.Values.global.default_mtu | default 9000}}
advertise_mtu = True

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 5 }}
rpc_state_report_workers = {{ .Values.rpc_state_workers | default .Values.global.rpc_state_workers | default 5 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

api_workers = {{ .Values.api_workers | default .Values.global.api_workers | default 12 }}
periodic_fuzzy_delay = 10

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "neutron" }}

{{- if contains ",f5" .Values.ml2_mechanismdrivers }}
[octavia]
base_url = http://{{include "octavia_api_endpoint_host_internal" .}}:9876
{{- end }}

[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}/v3
# DEPRECATED: auth_plugin
auth_plugin = v3password
auth_type = v3password
region_name = {{.Values.global.region}}
username = {{ .Values.global.nova_service_user | default "nova" | replace "$" "$$" }}
password = {{ .Values.global.nova_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
insecure = True
endpoint_type = internal

[designate]
url =  {{.Values.global.designate_api_endpoint_protocol_admin | default "http"}}://{{include "designate_api_endpoint_host_admin" .}}:{{ .Values.global.designate_api_port_admin| default 9001 }}/v2
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}/v3
auth_plugin = v3password
auth_type = v3password
region_name = {{.Values.global.region}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = master
project_domain_name = ccadmin
username = {{ .Values.global.designate_service_user | default "designate" | replace "$" "$$"}}
password = {{ .Values.global.designate_service_password | default "" | replace "$" "$$"}}
insecure = True
allow_reverse_dns_lookup = {{.Values.global.designate_allow_reverse_dns_lookup | default "False"}}
ipv4_ptr_zone_prefix_size = 24

[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

{{include "ini_sections.oslo_messaging_rabbit" .}}

[oslo_middleware]
enable_proxy_headers_parsing = true

[agent]
{{ if .Values.agent.rootwrap_daemon }}
root_helper = sudo
root_helper_daemon = neutron-rootwrap-daemon /etc/neutron/rootwrap.conf
{{ else }}
root_helper = neutron-rootwrap /etc/neutron/rootwrap.conf
{{ end }}

[database]
connection = {{ include "db_url_mysql" . }}
{{- include "ini_sections.database_options_mysql" . }}

[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
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

{{- include "osprofiler" . }}

{{- include "ini_sections.audit_middleware_notifications" . }}

{{- include "ini_sections.cache" . }}
