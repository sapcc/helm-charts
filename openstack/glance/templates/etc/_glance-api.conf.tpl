[DEFAULT]

{{- /* Build the backends list based on enabled values */ -}}
{{- $backends := list -}}
{{- if .Values.swift.enabled -}}
  {{- $backends = append $backends "swift:swift" -}}
{{- end -}}
{{- if .Values.ceph.enabled -}}
  {{- $backends = append $backends "ceph-rbd:rbd" -}}
{{- end -}}
{{- if .Values.ceph_s3.enabled -}}
  {{- $backends = append $backends "s3:s3" -}}
{{- end -}}

{{- /* Require at least one backend */ -}}
{{- if lt (len $backends) 1 -}}
  {{- fail "glance: At least one storage backend must be enabled." -}}
{{- end -}}

{{- /* Derive aliases from backends automatically (robust to types) */ -}}
{{- $aliases := list -}}
{{- range $_, $b := $backends -}}
  {{- $s := splitList ":" (printf "%v" $b) -}}
  {{- if lt (len $s) 2 -}}
    {{- fail (printf "glance: malformed backend entry %q (expected alias:driver)" $b) -}}
  {{- end -}}
  {{- $aliases = append $aliases (index $s 0) -}}
{{- end -}}
{{- $aliases = uniq $aliases -}}

{{- /* Compute and validate default backend (default: swift) */ -}}
{{- $def := (.Values.default_backend | default "swift") -}}
{{- if not (has $def $aliases) -}}
  {{- fail (printf "glance: default_backend %q is not in enabled_backends %v" $def $aliases) -}}
{{- end }}

enabled_backends = {{ join ", " $backends }}

debug = {{ .Values.api.debug }}

registry_host = 127.0.0.1

image_member_quota = 500

log_config_append = /etc/glance/logging.ini
{{- include "ini_sections.logging_format" . }}

node_staging_uri = file:///tmp/staging

show_image_direct_url = True

#disable default admin rights for role 'admin'
admin_role = ''

rpc_response_timeout = {{ .Values.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers }}
workers = {{ .Values.workers }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default 100 }}

image_size_cap = 2199023255552

[keystone_authtoken]
auth_plugin = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
insecure = True
token_cache_time = 600
service_token_roles_required = True
include_service_catalog = true
service_type = image
collect_timing = false
split_loggers = false

[paste_deploy]
flavor = keystone

[oslo_middleware]
enable_proxy_headers_parsing = true

[glance_store]
default_backend = {{ $def | quote }}

{{- if .Values.file.persistence.enabled }}
filesystem_store_datadir = /glance_store
{{- end }}

{{- if .Values.ceph.enabled }}

[ceph-rbd]
store_description = "Ceph RBD (fast)"
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_user = glance
rbd_store_pool = {{ .Values.ceph.pool }}
rbd_store_chunk_size = 8
rbd_store_access_timeout = 30
{{- end}}

{{- if .Values.ceph_s3.enabled }}

[s3]
store_description = "RGW S3 for Glance"
s3_store_host = {{ .Values.ceph_s3.store_host }}
s3_store_access_key = {{ .Values.ceph_s3.access_key }}
s3_store_secret_key = {{ .Values.ceph_s3.secret_key }}
s3_store_bucket = glance
s3_store_create_bucket_on_put = True
s3_store_large_object_size = 512
s3_store_large_object_chunk_size = 50
s3_store_thread_pool_size = 10
s3_store_bucket_url_format = path
{{- end }}

{{- if .Values.swift.enabled }}

[swift]
store_description = "Swift storage backend (default)"
swift_store_region={{.Values.global.region}}
swift_store_auth_insecure = True
swift_store_create_container_on_put = True
swift_buffer_on_upload = True
swift_upload_buffer_dir = /upload
swift_store_expire_soon_interval = 1800
swift_store_thread_pool_size = 10
swift_container_delete_timeout = 2
{{- if .Values.swift.multi_tenant }}
swift_store_multi_tenant = True
# swift_store_large_object_size = 5120
# swift_store_large_object_chunk_size = 200
# the following are deprecated but needed here https://github.com/openstack/glance_store/blob/stable/queens/glance_store/_drivers/swift/utils.py#L128-L145
swift_store_auth_version = 3
swift_store_auth_address = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
{{- else }}
swift_store_config_file = /etc/glance/swift-store.conf
default_swift_reference = swift-global
{{- end }}
{{- if .Values.swift.store_large_object_size }}
swift_store_large_object_size = {{.Values.swift.store_large_object_size}}
{{- end }}
swift_store_use_trusts=True
{{- end }}

[oslo_messaging_notifications]
driver = noop

[oslo_policy]
policy_file = /etc/glance/policy.yaml
enforce_new_defaults=False
enforce_scope=False

{{- include "ini_sections.cache" . }}

[barbican]
auth_endpoint = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
