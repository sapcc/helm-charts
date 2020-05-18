[DEFAULT]
debug = {{.Values.debug }}

log_config_append = /etc/manila/logging.ini

use_forwarded_for = true
# rate limiting is handled outside
api_rate_limit = false

# Manila requires 'share-type' for share creation.
# So, set here name of some share-type that will be used by default.
default_share_type = default

storage_availability_zone = {{ .Values.default_availability_zone | default .Values.global.default_availability_zone }}

# rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini

transport_url = {{ include "rabbitmq.transport_url" . }}

osapi_share_listen = 0.0.0.0
osapi_share_base_URL = https://{{include "manila_api_endpoint_host_public" .}}

# seconds between state report
report_interval = {{ .Values.report_interval | default 30 }}
service_down_time = {{ .Values.service_down_time | default 300 }}
periodic_interval = {{ .Values.periodic_interval | default 300 }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

delete_share_server_with_last_share = {{ .Values.delete_share_server_with_last_share | default false }}

scheduler_default_filters = AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter,ShareReplicationFilter
scheduler_default_share_group_filters = AvailabilityZoneFilter,ConsistentSnapshotFilter,CapabilitiesFilter,DriverFilter

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
quota_shares = 0
quota_gigabytes = 0
quota_snapshots = 0
quota_snapshot_gigabytes = 0
quota_share_networks = 0
quota_share_groups = 0
quota_share_group_snapshots = 0

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "manila" }}

[neutron]
auth_strategy = keystone
url = {{.Values.global.neutron_api_endpoint_protocol_internal | default "http"}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal | default 9696}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$"}}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
endpoint_type = internalURL
insecure = True

[oslo_messaging_rabbit]
rabbit_ha_queues = {{ .Values.rabbitmq.ha_queues | default "true" }}
rabbit_transient_queues_ttl={{ .Values.rabbit_transient_queues_ttl | default .Values.global.rabbit_transient_queues_ttl | default 60 }}

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
username = {{ .Values.global.manila_service_user | default "manila" | replace "$" "$$" }}
password = {{ .Values.global.manila_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
{{- if .Values.memcached.enabled }}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
{{- end }}
service_token_roles_required = True
service_token_roles = service
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = sharev2

{{- include "ini_sections.audit_middleware_notifications" . }}
{{- if .Values.memcached.enabled }}
{{- include "ini_sections.cache" . }}
{{- end }}
