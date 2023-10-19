{{- define "proxy-server.conf" -}}
[DEFAULT]
bind_port = 8080
# NOTE: value for prod, was 4 in staging before
workers = 8
user = swift
expose_info = true
# NOTE: value for prod, was 512 in staging before
max_clients = 1024
backlog = 4096
client_timeout = {{ .Values.client_timeout }}
{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[pipeline:main]
# Rocky or higher pipeline
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache listing_formats cname_lookup domain_remap bulk tempurl {{ if not .Values.sapcc_ratelimit.enabled }}ratelimit {{ end }}authtoken{{ if .Values.s3api_enabled }} s3api s3token {{ if not .Values.sapcc_ratelimit.enabled }}ratelimit{{ end }}{{ end }} {{if .Values.watcher_enabled }}watcher {{ end }}{{ if .Values.sapcc_ratelimit.enabled }}sapcc_ratelimit {{ end }}keystoneauth sysmeta-domain-override write-restriction staticweb copy container-quotas account-quotas slo dlo versioned_writes symlink proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
allow_account_management = true
account_autocreate = false
node_timeout = {{ .Values.node_timeout }}
recoverable_node_timeout = {{ .Values.recoverable_node_timeout }}
conn_timeout = 0.5
sorting_method = shuffle
{{- if .Values.debug }}
set log_level = DEBUG
{{- end }}

[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/proxy.disabled

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{ .Release.Namespace }}.svc:11211
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
max_manifest_segments = {{ .Values.max_manifest_segments }}
# Default is true with 2023.1 - we might need to pimp the object expirers before allow this
allow_async_delete = false

# Note: Put after auth and staticweb in the pipeline.
[filter:dlo]
use = egg:swift#dlo

[filter:gatekeeper]
use = egg:swift#gatekeeper

# swift3 requires keystoneauth with exact name
[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin, objectstore_admin
is_admin = false
# TODO: Replace by cloud_objectstore_admin when rolled out
reseller_admin_role = cloud_objectstore_admin
system_reader_roles = cloud_objectstore_viewer
project_reader_roles = objectstore_viewer
default_domain_id = default
{{- if .Values.debug }}
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
www_authenticate_uri = {{.Values.keystone_auth_uri}}
auth_url = {{.Values.keystone_auth_url}}
insecure = {{.Values.keystone_insecure | default false}}
interface = {{.Values.keystone_interface | default "admin"}}
{{- if .Values.token_memcached }}
memcached_servers = {{ .Values.token_memcached }}.{{ .Release.Namespace }}.svc:11211
{{- else }}
cache = swift.cache
{{- end }}
token_cache_time = {{ .Values.token_cache_time | default 600 }}
region_name = {{ .Values.region_name | default .Values.global.region }}
user_domain_name = {{ .Values.swift_service_user_domain }}
username = {{ .Values.swift_service_user }}
password = { fromEnv: SWIFT_SERVICE_PASSWORD }
project_domain_name = {{ .Values.swift_service_project_domain }}
project_name = {{ .Values.swift_service_project }}
service_token_roles_required = true
service_token_roles = service, admin
{{- if .Values.debug }}
set log_level = DEBUG
{{- end }}

[filter:sysmeta-domain-override]
use = egg:sapcc-swift-addons#sysmeta_domain_override

[filter:write-restriction]
use = egg:sapcc-swift-addons#write_restriction
allowed_roles = cloud_objectstore_admin

{{- if not .Values.sapcc_ratelimit.enabled }}

[filter:ratelimit]
use = egg:swift#ratelimit
set log_name = proxy-ratelimit
max_sleep_time_seconds = 20
log_sleep_time_seconds = 18
account_ratelimit = 10
container_ratelimit_0 = {{ .Values.ratelimit.container_ratelimit_0 | default 50 }}
container_ratelimit_100 = {{ .Values.ratelimit.container_ratelimit_100 | default 50 }}
container_listing_ratelimit_0 = 100
container_listing_ratelimit_100 = 100
{{- end }}

[filter:cname_lookup]
use = egg:swift#cname_lookup
lookup_depth = 2
storage_domain = {{ include "swift_endpoint_host" . }}{{ range $index, $csd := $.Values.additional_cname_storage_domains }},{{ $csd }}{{ end }}

[filter:domain_remap]
use = egg:swift#domain_remap
path_root = v1
reseller_prefixes = AUTH
storage_domain = {{ include "swift_endpoint_host" . }}

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
delete_container_retry_count = {{ .Values.bulk_delete_container_retry_count }}
delete_concurrency = {{ .Values.bulk_delete_concurrency }}

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
location = {{ .Values.global.region }}
# The standard swift proxy logging is needed
force_swift_request_proxy_log = true
max_upload_part_num = {{ .Values.max_manifest_segments }}

[filter:s3token]
use = egg:swift#s3token
auth_uri = {{ .Values.keystone_auth_url }}

{{- if .Values.s3_cred_cache_time }}
secret_cache_duration = {{ .Values.s3_cred_cache_time }}
auth_plugin = v3password
auth_version = 3
auth_url = {{ .Values.keystone_auth_url }}
insecure = {{ .Values.keystone_insecure | default false }}
interface = {{ .Values.keystone_interface | default "admin" }}
region_name = {{ .Values.region_name | default .Values.global.region }}
username = {{ .Values.swift_service_user }}
user_domain_name = {{ .Values.swift_service_user_domain }}
project_name = {{ .Values.swift_service_project }}
project_domain_name = {{ .Values.swift_service_project_domain }}
password = { fromEnv: SWIFT_SERVICE_PASSWORD }
{{- end }}

{{ if .Values.watcher_enabled -}}
[filter:watcher]
use = egg:watcher-middleware#watcher
config_file = /swift-etc/watcher.yaml
service_type = {{ required ".Values.global.serviceType" .Values.global.serviceType }}
cadf_service_name = {{ required ".Values.global.serviceName" .Values.global.serviceName }}
target_project_id_from_path = {{ .Values.watcher_project_id_from_path | default true }}
{{- end }}

{{ if .Values.sapcc_ratelimit.enabled -}}
[filter:sapcc_ratelimit]
use = egg:rate_limit_middleware#rate-limit
config_file = /swift-etc/sapcc-ratelimit.yaml
service_type = {{ required ".Values.global.serviceType missing" .Values.global.serviceType }}
cadf_service_name = {{ required ".Values.global.serviceName missing" .Values.global.serviceName }}
rate_limit_by = {{ required ".Values.sapcc_ratelimit.rateLimitBy missing" .Values.sapcc_ratelimit.rateLimitBy }}
max_sleep_time_seconds = {{ required ".Values.sapcc_ratelimit.maxSleepTimeSeconds missing" .Values.sapcc_ratelimit.maxSleepTimeSeconds }}
log_sleep_time_seconds = {{ required ".Values.sapcc_ratelimit.logSleepTimeSeconds missing" .Values.sapcc_ratelimit.logSleepTimeSeconds }}
backend_host = {{ include "sapcc_ratelimit_backend_host" . }}
backend_port = {{ required ".Values.sapcc_ratelimit.backend.port missing" .Values.sapcc_ratelimit.backend.port }}
{{- end }}

{{ end }}
