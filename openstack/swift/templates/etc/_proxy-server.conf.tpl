{{- define "proxy-server.conf" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
{{- $helm_release := index . 2 -}}
[DEFAULT]
bind_port = 8080
# NOTE: value for prod, was 4 in staging before
workers = 8
user = swift
expose_info = true
# NOTE: value for prod, was 512 in staging before
max_clients = 1024
backlog = 4096
client_timeout = {{ $context.client_timeout }}
log_statsd_host = localhost
log_statsd_port = 9125
log_statsd_default_sample_rate = 1.0
log_statsd_sample_rate_factor = 1.0
log_statsd_metric_prefix = swift
{{ if $context.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[pipeline:main]
# Rocky or higher pipeline
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats cname_lookup domain_remap bulk tempurl {{ if not $context.sapcc_ratelimit.enabled }}ratelimit {{ end }}authtoken{{ if and $context.s3api_enabled $cluster.seed }} s3api s3token {{ if not $context.sapcc_ratelimit.enabled }}ratelimit{{ end }}{{ end }} {{if $context.watcher_enabled }}watcher {{ end }}{{ if $context.sapcc_ratelimit.enabled }}sapcc_ratelimit {{ end }}keystoneauth sysmeta-domain-override staticweb copy container-quotas account-quotas slo dlo versioned_writes symlink proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = false
node_timeout = {{ $context.node_timeout }}
recoverable_node_timeout = {{ $context.recoverable_node_timeout }}
conn_timeout = 0.5
sorting_method = shuffle
{{- if $context.debug }}
set log_level = DEBUG
{{- end }}

[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/proxy.disabled

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{$helm_release.Namespace}}.svc:11211
memcache_max_connections = 32

# We only have one memcache, so the error suppression behavior is not useful for us.
# See also commit message on <https://github.com/openstack/swift/commit/aff65242ff87b24d43d7a6ce2b1c33546363144b>.
error_suppression_interval = 0

[filter:catch_errors]
use = egg:swift#catch_errors

[filter:proxy-logging]
use = egg:swift#proxy_logging
#
# Note: The double proxy-logging in the pipeline is not a mistake. The
# left-most proxy-logging is there to log requests that were handled in
# middleware and never made it through to the right-most middleware (and
# proxy server). Double logging is prevented for normal requests. See
# proxy-logging docs.

# Note: Put after auth and staticweb in the pipeline.
[filter:slo]
use = egg:swift#slo

# Note: Put after auth and staticweb in the pipeline.
[filter:dlo]
use = egg:swift#dlo

[filter:gatekeeper]
use = egg:swift#gatekeeper

# swift3 requires keystoneauth with exact name
[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin, swiftoperator
is_admin = false

{{- if $cluster.seed }}
reseller_admin_role = {{ $cluster.reseller_admin_role | default "swiftreseller" }}
{{- else }}
reseller_admin_role = {{ required "A valid cluster.reseller_admin_role entry required!" $cluster.reseller_admin_role }}
{{- end }}
default_domain_id = default
{{- if $context.debug }}
set log_level = DEBUG
{{- end }}
allow_overrides = true

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
delay_auth_decision = true
# TODO this can be set to false after that https://bugs.launchpad.net/keystonemiddleware/+bug/1933356 is fixed
include_service_catalog = true
service_type = object-store
auth_plugin = v3password
auth_version = 3
www_authenticate_uri = {{$cluster.keystone_auth_uri}}
auth_url = {{$cluster.keystone_auth_url}}
insecure = {{$cluster.keystone_insecure | default false}}
interface = {{$cluster.keystone_interface | default "admin"}}
{{- if $cluster.token_memcached }}
memcached_servers = {{ $cluster.token_memcached }}.{{ $helm_release.Namespace }}.svc:11211
{{- else }}
cache = swift.cache
{{- end }}
token_cache_time = {{$cluster.token_cache_time | default 600}}
region_name = {{$cluster.region_name | default $context.global.region}}
user_domain_name = {{$cluster.swift_service_user_domain}}
username = {{$cluster.swift_service_user}}
password = { fromEnv: SWIFT_SERVICE_PASSWORD }
project_domain_name = {{$cluster.swift_service_project_domain}}
project_name = {{$cluster.swift_service_project}}
service_token_roles_required = true
service_token_roles = service, admin
{{- if $context.debug }}
set log_level = DEBUG
{{- end }}

[filter:sysmeta-domain-override]
use = egg:sapcc-swift-addons#sysmeta_domain_override

{{- if not $context.sapcc_ratelimit.enabled }}

[filter:ratelimit]
use = egg:swift#ratelimit
set log_name = proxy-ratelimit
max_sleep_time_seconds = 20
log_sleep_time_seconds = 18
account_ratelimit = 10
container_ratelimit_0 = 50
container_ratelimit_100 = 50
container_listing_ratelimit_0 = 100
container_listing_ratelimit_100 = 100
{{- end }}

[filter:cname_lookup]
use = egg:swift#cname_lookup
lookup_depth = 2
storage_domain = {{tuple $cluster $context | include "swift_endpoint_host"}}{{ range $index, $csd := $cluster.additional_cname_storage_domains }},{{ $csd }}{{ end }}

[filter:domain_remap]
use = egg:swift#domain_remap
path_root = v1
reseller_prefixes = AUTH
storage_domain = {{tuple $cluster $context | include "swift_endpoint_host"}}

[filter:versioned_writes]
use = egg:swift#versioned_writes
allow_versioned_writes = true
# Enables Swift object-versioning API available since 2.24.0
allow_object_versioning = true

[filter:container_sync]
use = egg:swift#container_sync

[filter:tempurl]
use = egg:swift#tempurl

[filter:staticweb]
use = egg:swift#staticweb
url_base = https:

[filter:bulk]
use = egg:swift#bulk
delete_container_retry_count = {{ $context.bulk_delete_container_retry_count }}
delete_concurrency = {{ $context.bulk_delete_concurrency }}

[filter:container-quotas]
use = egg:swift#container_quotas

[filter:account-quotas]
use = egg:swift#account_quotas

[filter:copy]
use = egg:swift#copy

[filter:symlink]
use = egg:swift#symlink

[filter:listing_formats]
use = egg:swift#listing_formats

[filter:s3api]
use = egg:swift#s3api
location = {{ $context.global.region }}
# The standard swift proxy logging is needed
force_swift_request_proxy_log = true

[filter:s3token]
use = egg:swift#s3token
auth_uri = {{ $cluster.keystone_auth_url }}

{{- if $cluster.s3_cred_cache_time }}
secret_cache_duration = {{ $cluster.s3_cred_cache_time }}
auth_plugin = v3password
auth_version = 3
auth_url = {{ $cluster.keystone_auth_url }}
insecure = {{ $cluster.keystone_insecure | default false }}
interface = {{ $cluster.keystone_interface | default "admin" }}
region_name = {{ $cluster.region_name | default $context.global.region }}
username = {{ $cluster.swift_service_user }}
user_domain_name = {{ $cluster.swift_service_user_domain }}
project_name = {{ $cluster.swift_service_project }}
project_domain_name = {{ $cluster.swift_service_project_domain }}
password = { fromEnv: SWIFT_SERVICE_PASSWORD }
{{- end }}

{{ if $context.watcher_enabled -}}
[filter:watcher]
use = egg:watcher-middleware#watcher
config_file = /swift-etc/watcher.yaml
service_type = {{ required ".Values.global.serviceType" $context.global.serviceType }}
cadf_service_name = {{ required ".Values.global.serviceName" $context.global.serviceName }}
target_project_id_from_path = {{ $context.watcher_project_id_from_path | default true }}
{{- end }}

{{ if $context.sapcc_ratelimit.enabled -}}
[filter:sapcc_ratelimit]
use = egg:rate_limit_middleware#rate-limit
config_file = /swift-etc/sapcc-ratelimit.yaml
service_type = {{ required ".Values.global.serviceType missing" $context.global.serviceType }}
cadf_service_name = {{ required ".Values.global.serviceName missing" $context.global.serviceName }}
rate_limit_by = {{ required ".Values.sapcc_ratelimit.rateLimitBy missing" $context.sapcc_ratelimit.rateLimitBy }}
max_sleep_time_seconds = {{ required ".Values.sapcc_ratelimit.maxSleepTimeSeconds missing" $context.sapcc_ratelimit.maxSleepTimeSeconds }}
log_sleep_time_seconds = {{ required ".Values.sapcc_ratelimit.logSleepTimeSeconds missing" $context.sapcc_ratelimit.logSleepTimeSeconds }}
backend_host = {{ tuple $helm_release $context | include "sapcc_ratelimit_backend_host" }}
backend_port = {{ required ".Values.sapcc_ratelimit.backend.port missing" $context.sapcc_ratelimit.backend.port }}
{{- end }}

{{ end }}
