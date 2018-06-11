[DEFAULT]
debug = {{.Values.debug }}

log_config_append = /etc/manila/logging.ini

use_forwarded_for = true

# Following opt is used for definition of share backends that should be enabled.
# Values are conf groupnames that contain per manila-share service opts.
enabled_share_backends = netapp-multi

# Manila requires 'share-type' for share creation.
# So, set here name of some share-type that will be used by default.
default_share_type = default

storage_availability_zone = {{ .Values.default_availability_zone | default .Values.global.default_availability_zone }}

# rootwrap_config = /etc/manila/rootwrap.conf
api_paste_config = /etc/manila/api-paste.ini

transport_url = rabbit://{{ .Values.rabbitmq.users.default.user }}:{{ .Values.rabbitmq.users.default.password | default (tuple . .Values.rabbitmq.users.default.user | include "rabbitmq.password_for_user") }}@{{ include "release_rabbitmq_host" .}}:{{ .Values.rabbitmq.port | default 5672 }}{{ .Values.rabbitmq.virtual_host | default "/" }}

os_region_name = {{.Values.global.region}}

osapi_share_listen = 0.0.0.0

# seconds between state report
report_interval = {{ .Values.report_interval | default 10 }}
service_down_time = {{ .Values.service_down_time | default 60 }}
periodic_interval = {{ .Values.periodic_interval | default 60 }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 60 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}

delete_share_server_with_last_share = false

# Float representation of the over subscription ratio when thin
# provisioning is involved. Default ratio is 20.0, meaning provisioned
# capacity can be 20 times the total physical capacity. If the ratio
# is 10.5, it means provisioned capacity can be 10.5 times the total
# physical capacity. A ratio of 1.0 means provisioned capacity cannot
# exceed the total physical capacity. A ratio lower than 1.0 is
# invalid. (floating point value)
max_over_subscription_ratio = {{ .Values.max_over_subscription_ratio | default 2.0 }}

scheduler_default_filters = AvailabilityZoneFilter,CapacityFilter,CapabilitiesFilter
scheduler_default_share_group_filters = AvailabilityZoneFilter,ConsistentSnapshotFilter,CapabilitiesFilter,DriverFilter

# all default quotas are 0 to enforce usage of the Resource Management tool in Elektra
quota_shares = 0
quota_gigabytes = 0
quota_snapshots = 0
quota_snapshot_gigabytes = 0
quota_share_networks = 0
quota_share_groups = 0
quota_share_group_snapshots = 0

[neutron]
auth_strategy = keystone
url = {{.Values.global.neutron_api_endpoint_protocol_internal | default "http"}}://{{include "neutron_api_endpoint_host_internal" .}}:{{ .Values.global.neutron_api_port_internal | default 9696}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v3
auth_type = v3password
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$"}}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
insecure = True

[oslo_messaging_rabbit]
rabbit_ha_queues = {{ .Values.rabbitmq.ha_queues | default "true" }}
rabbit_transient_queues_ttl={{ .Values.rabbit_transient_queues_ttl | default .Values.global.rabbit_transient_queues_ttl | default 60 }}

[oslo_concurrency]
lock_path = /var/lib/manila/tmp

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v3
auth_type = v3password
username = {{ .Values.global.manila_service_user | default "manila" | replace "$" "$$" }}
password = {{ .Values.global.manila_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public | default 11211}}
insecure = True

{{- include "ini_sections.audit_middleware_notifications" . }}
