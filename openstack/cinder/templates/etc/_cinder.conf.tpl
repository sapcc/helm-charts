[DEFAULT]
log_config_append = /etc/cinder/logging.ini
backup_swift_url = https://objectstore-3.{{.Values.global.region}}.{{.Values.global.tld}}:443/v1/AUTH_
backup_swift_auth_version = 2
backup_driver = cinder.backup.drivers.swift.SwiftBackupDriver

{{- template "ini_sections.default_transport_url" . }}

enable_v2_api = True
enable_v3_api = True
volume_name_template = '%s'

glance_api_servers = {{.Values.global.glance_api_endpoint_protocol_internal | default "http"}}://{{include "glance_api_endpoint_host_internal" .}}:{{.Values.global.glance_api_port_internal | default "9292"}}
glance_api_version = 2

os_region_name = {{.Values.global.region}}
public_endpoint = https://{{include "cinder_api_endpoint_host_public" .}}:{{.Values.cinderApiPortPublic}}

default_availability_zone = {{.Values.global.default_availability_zone}}
default_volume_type = vmware

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "cinder" }}

api_paste_config = /etc/cinder/api-paste.ini
#nova_catalog_info = compute:nova:internalURL

auth_strategy = keystone

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

osapi_volume_workers = {{ .Values.osapi_volume_workers | default 16 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
{{- include "ini_sections.database_options_mysql" . }}

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
quota_volumes = 0
quota_snapshots = 0
quota_gigabytes = 0
quota_backups = -1
quota_backup_gigabytes = -1

# limit the volume size because it's limited by flexvols. in GB
per_volume_size_limit = {{ .Values.volume_size_limit_gb | default 2048 }}

# don't use quota class
use_default_quota_class=false

scheduler_default_filters = {{ .Values.scheduler_default_filters }}

{{- include "ini_sections.database" . }}

{{- include "osprofiler" . }}


[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.cinder_service_user | default "cinder"}}{{ .Values.global.user_suffix }}
password = {{ .Values.global.cinder_service_password | default (tuple . .Values.global.cinder_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
project_name = {{.Values.global.keystone_service_project | default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
service_token_roles_required = True
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = volumev3

[oslo_policy]
policy_file = /etc/cinder/policy.json

[oslo_concurrency]
lock_path = /var/lib/cinder/tmp

{{- include "ini_sections.audit_middleware_notifications" . }}

{{- include "ini_sections.cache" . }}

[barbican]
barbican_endpoint = internal
auth_endpoint = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3

[key_manager]
backend = barbican

[service_user]
send_service_user_token = true
auth_type = v3password
auth_version = v3
auth_interface = internal
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.cinder_service_user | default "cinder" }}{{ .Values.global.user_suffix }}
password = {{ .Values.global.cinder_service_password | default (tuple . .Values.global.cinder_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
project_name = "{{.Values.global.keystone_service_project | default "service" }}"
project_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
region_name = {{.Values.global.region}}
