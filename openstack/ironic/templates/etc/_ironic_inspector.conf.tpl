[DEFAULT]
log_config_append = /etc/ironic-inspector/logging.ini
{{- include "ini_sections.default_transport_url" . }}

[ironic]
region_name = {{.Values.global.region}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
username = {{ .Values.global.ironicServiceUser }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.ironicServicePassword | default (tuple . .Values.global.ironicServiceUser | include "identity.password_for_user")  | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}

[api]
host_ip = 0.0.0.0

[firewall]
manage_firewall = False

[processing]
store_data = swift
always_store_ramdisk_logs = true
ramdisk_logs_dir = /var/log/kolla/ironic/
add_ports = all
keep_ports = all
ipmi_address_fields = ilo_address
log_bmc_address = true
node_not_found_hook = enroll
default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks = $default_processing_hooks,local_link_connection

[discovery]
enroll_node_driver = agent_ipmitool

[pxe_filter]
driver = noop

[database]
{{- if eq .Values.mariadb.enabled true }}
connection = {{ tuple . "ironic_inspector" "ironic_inspector" .Values.inspectordbPassword | include "db_url_mysql" }}
{{- else }}
connection = {{ tuple . "ironic_inspector" "ironic_inspector" .Values.inspectordbPassword | include "db_url" }}
{{- end }}
{{- include "ini_sections.database_options" . }}

{{- include "ini_sections.audit_middleware_notifications" . }}

[keystone_authtoken]
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
auth_interface = internal
username = {{ .Values.global.ironicServiceUser }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.ironicServicePassword | default (tuple . .Values.global.ironicServiceUser| include "identity.password_for_user") }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
region_name = {{.Values.global.region}}
service_token_roles_required = True
insecure = True
token_cache_time = 600

[oslo_middleware]
enable_proxy_headers_parsing = True
