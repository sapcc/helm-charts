# masakari.conf
[DEFAULT]
{{- include "ini_sections.default_transport_url" . }}
log_config_append = /etc/masakari/logging.ini
state_path = /var/lib/masakari
masakari_api_listen_port = {{ .Values.masakariApiPortInternal }}
auth_strategy = keystone
memcache_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}

os_privileged_user_tenant = service
os_privileged_user_auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
os_privileged_user_name = masakari
os_privileged_user_password = {{ .Values.global.masakari_service_password }}

wait_period_after_service_update = 181

{{- include "ini_sections.logging_format" . }}

[oslo_concurrency]
lock_path = /var/lib/masakari/tmp

[keystone_authtoken]
auth_type = v3password
auth_version = v3
auth_interface = internal
www_authenticate_uri = https://{{include "keystone_api_endpoint_host_public" .}}/v3
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
user_domain_name = "Default"
project_name = "service"
project_domain_name = "Default"
region_name = {{.Values.global.region}}
memcached_servers = {{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port | default 11211 }}
insecure = True
token_cache_time = 600
include_service_catalog = true
service_type = masakari
service_token_roles_required = True

[oslo_messaging_notifications]
driver = noop

[oslo_middleware]
enable_proxy_headers_parsing = true

[oslo_policy]
policy_file = /etc/masakari/policy.yaml

{{- include "ini_sections.cache" . }}

[wsgi]
api_paste_config = /var/lib/openstack/etc/masakari/api-paste.ini

[host_failure]
evacuate_all_instances = true
add_reserved_host_to_aggregate = true

[instance_failure]
process_all_instances = true

[taskflow_driver_recovery_flows]
host_auto_failure_recovery_tasks = pre:[{{ join "," .Values.recovery_flows.host_auto.pre }}],main:[{{ join "," .Values.recovery_flows.host_auto.main }}],post:[{{ join "," .Values.recovery_flows.host_auto.post }}]
host_rh_failure_recovery_tasks = pre:[{{ join "," .Values.recovery_flows.host_reserved.pre }}],main:[{{ join "," .Values.recovery_flows.host_reserved.main }}],post:[{{ join "," .Values.recovery_flows.host_reserved.post }}]
instance_failure_recovery_tasks = pre:[{{ join "," .Values.recovery_flows.instance.pre }}],main:[{{ join "," .Values.recovery_flows.instance.main }}],post:[{{ join "," .Values.recovery_flows.instance.post }}]