[DEFAULT]
debug = {{.Values.debug }}

log_config_append = /etc/manila/logging.ini
{{- include "ini_sections.logging_format" . }}

use_forwarded_for = true
# rate limiting is handled outside
api_rate_limit = {{ .Values.api_rate_limit.enabled | default false }}

# Manila requires 'share-type' for share creation.
# So, set here name of some share-type that will be used by default.
default_share_type = default

storage_availability_zone = {{ .Values.default_availability_zone | default .Values.global.default_availability_zone }}

# rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini

osapi_share_listen = 0.0.0.0
osapi_share_base_URL = https://{{include "manila_api_endpoint_host_public" .}}

# seconds between state report
report_interval = {{ .Values.report_interval | default 30 }}
service_down_time = {{ .Values.service_down_time | default 600 }}
periodic_interval = {{ .Values.periodic_interval | default 60 }}
periodic_fuzzy_delay = {{ .Values.periodic_interval | default 20 }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}
rpc_ping_enabled = {{ .Values.rpc_ping_enabled }}

# time to live in sec of idle connections in the pool:
conn_pool_ttl = {{ .Values.rpc_conn_pool_ttl | default 600 }}

netapp_volume_snapshot_reserve_percent = {{ .Values.netapp_volume_snapshot_reserve_percent | default 50 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

delete_share_server_with_last_share = {{ .Values.delete_share_server_with_last_share | default false }}

use_scheduler_creating_share_from_snapshot = {{ .Values.use_scheduler_creating_share_from_snapshot | default false }}

is_deferred_deletion_enabled = {{ .Values.is_deferred_deletion_enabled | default false }}

periodic_deferred_delete_interval = {{ .Values.periodic_deferred_delete_interval | default 300 }}

scheduler_default_filters = {{ .Values.scheduler_default_filters | default "AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter,ShareReplicationFilter,AffinityFilter,AntiAffinityFilter,OnlyHostFilter" }}
scheduler_default_weighers = CapacityWeigher,GoodnessWeigher,HostAffinityWeigher
scheduler_default_share_group_filters = AvailabilityZoneFilter,ConsistentSnapshotFilter,CapabilitiesFilter,DriverFilter

migration_ignore_scheduler = True
# default time to wait for access rules to become active in migration cutover was 180 seconds
migration_wait_access_rules_timeout = 3600

# options for manila.share.manager
server_migration_driver_continue_update_interval = {{ .Values.server_migration_driver_continue_update_interval | default 900 }}
server_migration_extend_neutron_network = {{ .Values.server_migration_extend_neutron_network | default true }}
ensure_driver_resources_interval = {{ .Values.ensure_driver_resources_interval | default 14400 }}

statsd_port = {{ .Values.rpc_statsd_port }}
statsd_enabled = {{ .Values.rpc_statsd_enabled }}

{{- template "utils.snippets.debug.eventlet_backdoor_ini" "manila" }}

[quota]
shares = {{ .Values.quota.shares }}
gigabytes = {{ .Values.quota.gigabytes }}
snapshots = {{ .Values.quota.snapshots }}
snapshot_gigabytes = {{ .Values.quota.snapshot_gigabytes }}
share_networks = {{ .Values.quota.share_networks }}
share_groups = {{ .Values.quota.share_groups }}
share_group_snapshots = {{ .Values.quota.share_group_snapshots }}
share_replicas = {{ .Values.quota.share_replicas }}
replica_gigabytes = {{ .Values.quota.replica_gigabytes }}

[neutron]
auth_strategy = keystone
url = {{.Values.global.neutron_api_endpoint_protocol_internal | default "http"}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal | default 9696}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
auth_type = v3password
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
endpoint_type = internalURL
insecure = True

[oslo_policy]
policy_file = /etc/manila/policy.yaml

{{- include "ini_sections.oslo_messaging_rabbit" .}}
rabbit_interval_max = {{ .Values.rabbitmq.max_reconnect_interval | default 3 }}

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

{{ include "ini_sections.coordination" . }}

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
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

{{- if .Values.memcached.enabled }}
{{- include "ini_sections.cache" . }}
{{- end }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
