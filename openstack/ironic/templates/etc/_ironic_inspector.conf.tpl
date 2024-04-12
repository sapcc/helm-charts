[DEFAULT]
log_config_append = /etc/ironic-inspector/logging.ini
{{- include "ini_sections.logging_format" . }}

clean_up_period = 120
# Timeout after which introspection is considered failed, set to 0 to
# disable. (integer value)
timeout = 3600
debug = true
standalone = {{ .Values.inspector.standalone }}
rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
executor_thread_pool_size = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 100 }}

# time to live in sec of idle connections in the pool:
conn_pool_ttl = {{ .Values.rpc_conn_pool_ttl | default 600 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}
statsd_port = {{ .Values.inspector.rpc_statsd_port }}
statsd_enabled = {{ .Values.inspector.rpc_statsd_enabled }}
listen_address = 0.0.0.0
host = https://{{ include "ironic_inspector_endpoint_host_public" .}}

[ironic]
region_name = {{.Values.global.region}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}

[firewall]
manage_firewall = False

[processing]
store_data = none
always_store_ramdisk_logs = true
ramdisk_logs_dir = /var/log/ironic-inspector/ramdisk
add_ports = all
keep_ports = all
ipmi_address_fields = ilo_address
log_bmc_address = true
node_not_found_hook = enroll
power_off = False
default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks = $default_processing_hooks,local_link_connection
#default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices

[discovery]
enroll_node_driver = ipmi
enroll_node_fields = conductor_group:testing

[pxe_filter]
driver = noop

[database]
{{- include "ini_sections.database_options_mysql" . }}

[keystone_authtoken]
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
auth_interface = internal
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
region_name = {{.Values.global.region}}
service_token_roles_required = True
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = baremetal-introspection

[oslo_middleware]
enable_proxy_headers_parsing = True
