# neutron.conf
[DEFAULT]
debug = {{.Values.debug}}
verbose=True

log_config_append = /etc/neutron/logging.conf

#lock_path = /var/lock/neutron
api_paste_config = /etc/neutron/api-paste.ini

allow_pagination = true
allow_sorting = true
pagination_max_limit = 500

interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver

allow_overlapping_ips = true
core_plugin = ml2

service_plugins={{.Values.service_plugins}}

default_router_type = {{.Values.default_router_type}}
router_scheduler_driver = {{.Values.router_scheduler_driver}}

max_fixed_ips_per_port = {{.Values.max_fixed_ips_per_port | default 25}}

dhcp_agent_notification = true
network_auto_schedule = True
allow_automatic_dhcp_failover = True
dhcp_agents_per_network=2
dhcp_lease_duration = {{.Values.dhcp_lease_duration}}

# Designate configuration
dns_domain =  {{.Values.dns_local_domain}}
external_dns_driver = {{.Values.dns_external_driver}}

global_physnet_mtu = {{.Values.global.default_mtu | default 9000}}
advertise_mtu = True

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 5 }}
rpc_state_report_workers = {{ .Values.rpc_state_workers | default .Values.global.rpc_state_workers | default 5 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

api_workers = {{ .Values.api_workers | default .Values.global.api_workers | default 8 }}

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "neutron" }}

[nova]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v3
auth_plugin = v3password
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
admin_auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v2.0
admin_username = {{ .Values.global.designate_service_user | default "designate" | replace "$" "$$"}}
admin_password = {{ .Values.global.designate_service_password | default "" | replace "$" "$$"}}
admin_tenant_name = {{.Values.global.keystone_service_project | default "master"}}
insecure=True
allow_reverse_dns_lookup = {{.Values.global.designate_allow_reverse_dns_lookup | default "False"}}
ipv4_ptr_zone_prefix_size = 24


[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

{{include "oslo_messaging_rabbit" .}}

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

connection = postgresql://{{ default .Release.Name .Values.global.dbUser }}:{{ .Values.global.dbPassword }}@{{include "neutron_db_host" .}}:{{.Values.global.postgres_port_public | default 5432}}/{{ default .Release.Name .Values.postgresql.postgresDatabase}}
max_pool_size = {{ .Values.max_pool_size | default .Values.global.max_pool_size | default 5 }}
{{- if or .Values.postgresql.pgbouncer.enabled .Values.global.pgbouncer.enabled }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default -1 }}
{{- else }}
max_overflow = {{ .Values.max_overflow | default .Values.global.max_overflow | default 10 }}
{{- end }}


[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357 }}/v3
auth_type = v3password
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcache_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public | default 11211}}
insecure = True

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
