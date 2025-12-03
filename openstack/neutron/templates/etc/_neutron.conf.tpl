# neutron.conf
[DEFAULT]
debug = {{.Values.debug}}
verbose = True

log_config_append = /etc/neutron/logging.conf
{{- include "ini_sections.logging_format" . }}

api_paste_config = /etc/neutron/api-paste.ini

pagination_max_limit = 500
max_allowed_address_pair = {{.Values.max_allowed_address_pair | default 50}}
max_routes = {{.Values.max_routes | default 256}}

allow_overlapping_ips = true
core_plugin = ml2

service_plugins = {{required "A valid .Values.service_plugins required!" .Values.service_plugins}},flavors{{- if .Values.interconnection.enabled }},networking-interconnection{{- end}}{{- if .Values.vpnaas.enabled }},vpnaas{{- end }}

default_router_type = {{required "A valid .Values.default_router_type required!" .Values.default_router_type}}
router_scheduler_driver = {{required "A valid .Values.router_scheduler_driver required!" .Values.router_scheduler_driver}}
router_auto_schedule = {{ .Values.router_auto_schedule | default "false" }}
allow_automatic_l3agent_failover = {{ .Values.allow_automatic_l3agent_failover | default "false" }}

network_scheduler_driver = neutron.scheduler.dhcp_agent_scheduler.AZAwareWeightScheduler
allow_automatic_dhcp_failover = {{ .Values.allow_automatic_dhcp_failover | default "false" }}
dhcp_agents_per_network = 2
dhcp_lease_duration = {{ .Values.dhcp_lease_duration | default 86400 }}

filter_validation = false

# Designate configuration
dns_domain = {{required "A valid .Values.dns_local_domain required!" .Values.dns_local_domain}}
{{- if .Values.dns_external_driver }}
external_dns_driver = {{required "A valid .Values.dns_external_driver required!" .Values.dns_external_driver}}
{{- end }}

global_physnet_mtu = {{.Values.global.default_mtu | default 9000}}
advertise_mtu = True

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers }}
rpc_state_report_workers = {{ .Values.rpc_state_workers }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

api_workers = {{ .Values.api_workers }}
periodic_fuzzy_delay = 10

{{- if not (empty .Values.api.owner_check_cache_expiration_time) }}
owner_check_cache_expiration_time = {{ .Values.api.owner_check_cache_expiration_time }}
{{- end }}

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "neutron" }}

[service_providers]
service_provider = L3_ROUTER_NAT:asr1k:asr1k_neutron_l3.neutron.services.service_providers.asr1k_router.ASR1KRouterDriver:default
{{- if .Values.vpnaas.enabled }}
service_provider = VPN:cisco_ipsec:asr1k_neutron_l3.neutron.services.service_drivers.asr1k.vpnaas_driver.ASR1KIPSecVPNaaSDriver:default
{{- end }}

[oslo_policy]
enforce_scope = False
enforce_new_defaults = False

[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}/v3
# DEPRECATED: auth_plugin
auth_plugin = v3password
auth_type = v3password
region_name = {{.Values.global.region}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
insecure = True
endpoint_type = internal

[placement]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}/v3
auth_type = v3password
region_name = {{.Values.global.region}}
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
insecure = True
allow_reverse_dns_lookup = {{.Values.global.designate_allow_reverse_dns_lookup | default "False"}}
ipv4_ptr_zone_prefix_size = 24
ptr_zone_email = dns@sap-ag.de

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

[database]
{{- include "ini_sections.database_options_mysql" . }}

[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
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

[privsep]
# The number of threads available for privsep to concurrently run processes.
# Defaults to the number of CPU cores in the system (integer value)
# Minimum value: 1
thread_pool_size = 3

[metadata_rate_limiting]
rate_limit_enabled = {{ .Values.metadata.rate_limit.enabled }}
base_window_duration = {{ .Values.metadata.rate_limit.base_window_duration }}
base_query_rate_limit = {{ .Values.metadata.rate_limit.base_query_rate_limit }}
burst_window_duration = {{ .Values.metadata.rate_limit.burst_window_duration }}
burst_query_rate_limit = {{ .Values.metadata.rate_limit.burst_query_rate_limit }}

{{- include "ini_sections.cache" . }}

{{- if hasPrefix "caracal" .Values.imageVersion }}
[experimental]
linuxbridge = true
{{- end }}
{{- if .Values.vpnaas.enabled }}

[vpnaas]
disconnected_subnets_mode = true
{{- end }}
{{- if .Values.customdns.enabled }}

[customdns]
enabled = true
{{- if .Values.customdns.upstream_dns_servers }}
upstream_dns_servers = {{ join "," .Values.customdns.upstream_dns_servers }}
{{- end }}
{{- if .Values.customdns.project_ids }}
project_ids = {{ join "," .Values.customdns.project_ids }}
{{- end }}
{{- if .Values.customdns.domain_name_prefixes }}
domain_name_prefixes = {{ join "," .Values.customdns.domain_name_prefixes }}
{{- end }}
{{- end }}
