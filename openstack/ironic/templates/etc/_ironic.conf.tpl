[DEFAULT]
log_config_append = /etc/ironic/logging.ini
{{- include "ini_sections.logging_format" . }}

{{- if contains "xena" .Values.imageVersion }}
pybasedir = /var/lib/openstack/lib/python3.8/site-packages/ironic
{{- else }}
pybasedir = /var/lib/openstack/lib/python3.6/site-packages/ironic
{{- end }}

network_provider = neutron_plugin
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron
{{- if .Values.notification_level }}
notification_level = {{ .Values.notification_level }}
versioned_notifications_topics = {{ .Values.versioned_notifications_topics  | default "ironic_versioned_notifications" | quote }}
{{- end }}

{{- include "ini_sections.default_transport_url" . }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 100 }}
executor_thread_pool_size = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 64 }}

# time to live in sec of idle connections in the pool:
conn_pool_ttl = {{ .Values.rpc_conn_pool_ttl | default 600 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}

{{- if .Values.notification_level }}
[oslo_messaging_notifications]
driver = messagingv2
{{- end }}

[agent]
image_download_source = swift
deploy_logs_collect = {{ .Values.agent.deploy_logs.collect }}
deploy_logs_storage_backend = {{ .Values.agent.deploy_logs.storage_backend }}
deploy_logs_swift_days_to_expire = {{ .Values.agent.deploy_logs.swift_days_to_expire }}
{{- if eq .Values.agent.deploy_logs.storage_backend "swift" }}
deploy_logs_swift_project_name = {{ .Values.agent.deploy_logs.swift_project_name | required "Need a project name" }}
deploy_logs_swift_project_domain_name = {{ .Values.agent.deploy_logs.swift_project_domain_name | required "Need a domain name for the project" }}
deploy_logs_swift_container = {{ .Values.agent.deploy_logs.swift_container | default "ironic_deploy_logs_container" }}
{{- end }}

[inspector]
auth_section = service_catalog

[dhcp]
dhcp_provider = neutron

[api]
host_ip = 0.0.0.0
public_endpoint = https://{{ include "ironic_api_endpoint_host_public" .}}
api_workers = {{ .Values.api.api_workers }}

[database]
{{- include "ini_sections.database_options_mysql" . }}

[keystone]
auth_section = keystone_authtoken
region = {{ .Values.global.region }}

[keystone_authtoken]
auth_type = v3password
auth_interface = internal
auth_version = v3
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
region_name = {{ .Values.global.region }}
insecure = True
service_token_roles_required = True
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
token_cache_time = 600
include_service_catalog = true
service_type = baremetal

[service_catalog]
auth_section = service_catalog
valid_interfaces = public {{- /* Public, so that the ironic-python-agent doesn't get a private url */}}
region_name = {{ .Values.global.region }}
# auth_section
auth_type = v3password
auth_version = v3
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
insecure = True

[glance]
auth_section = service_catalog
swift_temp_url_duration = 3600
# No terminal slash, it will break the url signing scheme
swift_endpoint_url = {{ .Values.global.swift_endpoint_protocol | default "https" }}://{{ include "swift_endpoint_host" . }}:{{ .Values.global.swift_api_port_public | default 443 }}
swift_api_version = v1

[swift]
auth_section = service_catalog
{{- if .Values.swift_set_temp_url_key }}
swift_set_temp_url_key = True
{{- end }}

[neutron]
auth_section = service_catalog
cleaning_network = {{required "A valid .Values.network_cleaning_uuid required!" .Values.network_cleaning_uuid }}
provisioning_network = {{required "A valid .Values.network_management_uuid required!" .Values.network_management_uuid }}
timeout = {{ .Values.neutron_url_timeout }}
port_setup_delay = {{ .Values.neutron_port_setup_delay }}

# only works with nova api version >= 2.76
# enable once nova is upgraded to xena
#[nova]
#auth_section = service_catalog
#service_type = compute
#service_name = nova

[oslo_middleware]
enable_proxy_headers_parsing = True

{{- if .Values.watcher.enabled }}
[watcher]
enabled = true
service_type = baremetal
config_file = /etc/ironic/watcher.yaml
{{ end }}

{{ if .Values.audit.enabled }}
[audit]
enabled = True
audit_map_file = /etc/ironic/api_audit_map.yaml
ignore_req_list = GET, HEAD
record_payloads = {{ if .Values.audit.record_payloads -}}True{{- else -}}False{{- end }}
metrics_enabled = {{ if .Values.audit.metrics_enabled -}}True{{- else -}}False{{- end }}

{{- end }}

{{- include "osprofiler" . }}

{{- include "ini_sections.cache" . }}
