[DEFAULT]
log_config_append = /etc/ironic-inspector/logging.ini
{{- include "ini_sections.default_transport_url" . }}
clean_up_period = 60
# Timeout after which introspection is considered failed, set to 0 to
# disable. (integer value)
timeout = 3600
debug = true
standalone = {{ .Values.inspector.standalone }}

[ironic]
region_name = {{.Values.global.region}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
username = {{ .Values.global.ironicServiceUser }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.ironicServicePassword is missing" .Values.global.ironicServicePassword }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}

[api]
listen_address = 0.0.0.0
host = https://{{ include "ironic_inspector_endpoint_host_public" .}}

[firewall]
manage_firewall = False

[coordination]
backend_url = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}

[processing]
store_data = none
always_store_ramdisk_logs = true
ramdisk_logs_dir = /var/log/ironic-inspector/ramdisk
add_ports = all
keep_ports = all
ipmi_address_fields = ilo_address
log_bmc_address = true
node_not_found_hook = enroll
default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices,extra_hardware
processing_hooks = $default_processing_hooks,local_link_connection
#default_processing_hooks = ramdisk_error,root_disk_selection,scheduler,validate_interfaces,capabilities,pci_devices

[discovery]
enroll_node_driver = ipmi
enroll_node_fields = conductor_group:testing

[pxe_filter]
driver = noop

[database]
{{- if eq .Values.mariadb.enabled true }}
connection = mysql+pymysql://ironic_inspector:{{.Values.inspectordbPassword}}@ironic-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}/ironic_inspector?charset=utf8
{{- include "ini_sections.database_options_mysql" . }}
{{- else }}
connection = {{ tuple . "ironic_inspector" "ironic_inspector" .Values.inspectordbPassword | include "db_url" }}
{{- include "ini_sections.database_options" . }}
{{- end }}

{{- include "ini_sections.audit_middleware_notifications" . }}

[keystone_authtoken]
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
auth_interface = internal
username = {{ .Values.global.ironicServiceUser }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.ironicServicePassword is missing" .Values.global.ironicServicePassword }}
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
