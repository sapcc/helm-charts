# placement.conf
[DEFAULT]
log_config_append = /etc/placement/logging.ini
state_path = /var/lib/placement

memcache_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}

{{- include "ini_sections.logging_format" . }}

[placement_database]
{{- include "ini_sections.database_options_mysql" . }}


{{- include "osprofiler" . }}

[oslo_concurrency]
lock_path = /var/lib/placement/tmp

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
project_name = "{{.Values.global.keystone_service_project | default "service" }}"
project_domain_name = "{{.Values.global.keystone_service_domain | default "Default" }}"
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = placement
service_token_roles_required = True

[oslo_messaging_notifications]
driver = noop

[oslo_middleware]
enable_proxy_headers_parsing = true

[oslo_policy]
policy_file = /etc/placement/policy.yaml

{{- include "ini_sections.cache" . }}

{{- include "util.helpers.valuesToIni" .Values.placement_conf }}
