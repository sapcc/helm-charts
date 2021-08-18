# nova.conf
[DEFAULT]
{{- range $k, $v := .Values.default }}
{{ $k }} = {{ $v }}
{{- end }}

log_config_append = /etc/nova/logging.ini
logging_context_format_string = %(asctime)s.%(msecs)03d %(process)d %(levelname)s %(name)s [%(request_id)s g%(global_request_id)s %(user_identity)s] %(instance)s%(message)s
state_path = /var/lib/nova

# we patched this to be treated as force_resize_to_same_host for mitaka
# https://github.com/sapcc/nova/commit/fd9508038351d027dcbf94282ba83caed5864a97
allow_resize_to_same_host = true
# but now we also need a new patch with this for queens
always_resize_on_same_host = {{ .Values.always_resize_on_same_host | default false }}

enable_new_services = {{ .Values.enable_new_services | default .Release.IsInstall }}
service_down_time = {{ .Values.service_down_time | default 60 }}

memcache_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}

default_schedule_zone = {{.Values.global.default_availability_zone}}
default_availability_zone = {{.Values.global.default_availability_zone}}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

sync_power_state_pool_size = {{ .Values.sync_power_state_pool_size | default 500 }}
sync_power_state_interval = {{ .Values.sync_power_state_interval | default 1200 }}
sync_power_state_unexpected_call_stop = false

prepare_empty_host_for_spawning_interval = 600

dhcp_domain = openstack.{{ required ".Values.global.region is missing" .Values.global.region }}.{{ required ".Values.global.tld is missing" .Values.global.tld }}

{{ include "ini_sections.default_transport_url" . }}

{{ template "utils.snippets.debug.eventlet_backdoor_ini" "nova" }}

[api]
compute_link_prefix = https://{{include "nova_api_endpoint_host_public" .}}:{{.Values.global.novaApiPortPublic}}

[api_database]
connection = mysql+pymysql://{{.Values.apidbUser}}:{{.Values.apidbPassword | urlquery}}@nova-api-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}/nova_api?charset=utf8
{{- include "ini_sections.database_options_mysql" . }}

{{ include "ini_sections.database" . }}

[quota]
{{- range $k, $v := .Values.quota }}
{{ $k }} = {{ $v }}
{{- end }}

# usage refreshes on new reservations, 0 means disabled
# number of seconds between subsequent usage refreshes
max_age = {{ .Values.usage_max_age | default 0 }}
# count of reservations until usage is refreshed
until_refresh = {{ .Values.usage_until_refresh | default 0 }}

{{- include "osprofiler" . }}

[spice]
enabled = True
html5proxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{.Values.global.novaConsolePortPublic}}/spicehtml5/spice_auto.html

[vnc]
enabled = True
server_listen = $my_ip
server_proxyclient_address = $my_ip
novncproxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/novnc/vnc_auto.html?path=/novnc/websockify
novncproxy_host = 0.0.0.0
novncproxy_port = {{ .Values.consoles.novnc.portInternal }}

[serial_console]
enabled = True
base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/serial

[shellinabox]
host = 0.0.0.0
port = {{ .Values.consoles.shellinabox.portInternal }}
base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/shellinabox
proxyclient_url = https://{{include "ironic_console_endpoint_host_public" .}}

{{- if .Values.consoles.mks }}
[mks]
enabled = True
mksproxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{.Values.global.novaConsolePortPublic}}/mks/vnc_auto.html?path=mks/websockify
{{- end }}

{{- include "ini_sections.oslo_messaging_rabbit" .}}

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[glance]
api_servers = http://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal | default "9292" }}
num_retries = 10

[cinder]
os_region_name = {{.Values.global.region}}
cross_az_attach={{.Values.cross_az_attach}}
auth_url = http://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default "5000" }}/v3
auth_type = v3password
username = {{ .Values.global.nova_service_user | default "nova" }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default" }}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project | default "service" }}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default" }}
http_retries = {{.Values.cinder_http_retries}}

[neutron]
metadata_proxy_shared_secret = {{ .Values.global.nova_metadata_secret }}
service_metadata_proxy = true
auth_url = http://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default "5000" }}/v3
auth_type = v3password
username = {{ .Values.global.nova_service_user | default "nova" }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default" }}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project | default "service" }}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default" }}
http_retries = {{.Values.neutron_http_retries}}
timeout = {{.Values.neutron_timeout}}

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.nova_service_user | default "nova" }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password }}
user_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
project_name = "{{.Values.global.keystone_service_project | default "service" }}"
project_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = compute
service_token_roles_required = True

#[upgrade_levels]
#compute = auto

[oslo_messaging_notifications]
driver = noop

[oslo_middleware]
enable_proxy_headers_parsing = true

[placement]
auth_type = v3password
auth_version = v3
auth_url = http://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default "5000" }}/v3
username = {{.Values.global.placement_service_user}}
password = {{ required ".Values.global.placement_service_password is missing" .Values.global.placement_service_password }}
user_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
project_name = service
project_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
valid_interfaces = internal
region_name = {{.Values.global.region}}

{{- include "ini_sections.audit_middleware_notifications" . }}

{{- include "ini_sections.cache" . }}

[barbican]
backend = barbican
auth_endpoint = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3

[service_user]
send_service_user_token = true
auth_type = v3password
auth_version = v3
auth_interface = internal
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.nova_service_user | default "nova" }}{{ .Values.global.user_suffix }}
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password }}
user_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
project_name = "{{.Values.global.keystone_service_project | default "service" }}"
project_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
region_name = {{.Values.global.region}}

[wsgi]
default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

[workarounds]
# This has to be removed when we also remove the deployment of nova-consoleauth
enable_consoleauth = True
