[DEFAULT]
bind_port = 8080
# NOTE: value for prod, was 4 in staging before
workers = 8
user = swift
expose_info = true
# NOTE: value for prod, was 512 in staging before
max_clients = 1024
backlog = 4096
log_statsd_host = localhost
log_statsd_port = 9125
log_statsd_default_sample_rate = 1.0
log_statsd_sample_rate_factor = 1.0
log_statsd_metric_prefix = swift
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[pipeline:main]
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache cname_lookup domain_remap bulk tempurl ratelimit authtoken keystone staticweb container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server
# pipeline = catch_errors gatekeeper healthcheck proxy-logging cache cname_lookup domain_remap statsd container_sync bulk tempurl ratelimit authtoken keystone staticweb container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server
# TODO: sentry middleware (between "proxy-logging" and "proxy-server") disabled temporarily because of weird exceptions tracing into raven, need to check further

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = false
node_timeout = 60
recoverable_node_timeout = 10
conn_timeout = 0.5
sorting_method = shuffle
{{ if .Values.debug -}}
set log_level = DEBUG
{{- end }}

[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/proxy.disabled

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{.Release.Namespace}}.svc:11211
memcache_max_connections = 10

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

[filter:keystone]
use = egg:swift#keystoneauth
operator_roles = admin, swiftoperator
is_admin = false
cache = swift.cache
reseller_admin_role = swiftreseller
default_domain_id = default
{{ if .Values.debug -}}
set log_level = DEBUG
{{- end }}
allow_overrides = true

[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
delay_auth_decision = true
include_service_catalog = false
auth_plugin = v3password
auth_version = 3
auth_uri = {{.Values.keystone_auth_uri}}
auth_url = {{.Values.keystone_auth_url}}
insecure = false
cache = swift.cache
region_name = {{.Values.global.region}}
user_domain_name = Default
username = swift
password = {{.Values.swift_service_password}}
project_domain_name = Default
project_name = {{.Values.swift_service_project}}
{{ if .Values.debug -}}
set log_level = DEBUG
{{- end }}

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

[filter:cname_lookup]
use = egg:swift#cname_lookup
lookup_depth = 2
storage_domain = {{.Values.cname_lookup_storage_domain}}
storage_host = {{.Values.cname_lookup_storage_host}}

[filter:domain_remap]
use = egg:swift#domain_remap
path_root = v1
reseller_prefixes = AUTH
storage_domain = {{ include "swift_endpoint_host" . }}

[filter:versioned_writes]
use = egg:swift#versioned_writes
allow_versioned_writes = true

[filter:container_sync]
use = egg:swift#container_sync

[filter:tempurl]
use = egg:swift#tempurl

[filter:staticweb]
use = egg:swift#staticweb

[filter:bulk]
use = egg:swift#bulk

[filter:container-quotas]
use = egg:swift#container_quotas

[filter:account-quotas]
use = egg:swift#account_quotas

# [filter:statsd]
# use = egg:ops-middleware#statsd
# statsd_host = localhost
# statsd_port = 9125
# statsd_replace = swift
#
# [filter:sentry]
# use = egg:ops-middleware#sentry
# dsn = {{.Values.sentry_dsn}}
# level = ERROR
