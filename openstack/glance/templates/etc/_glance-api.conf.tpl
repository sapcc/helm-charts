[DEFAULT]
debug = {{.Values.api.debug}}

registry_host = 127.0.0.1

log_config_append = /etc/glance/logging.conf

show_image_direct_url= True

#disable default admin rights for role 'admin'
admin_role = ''

rpc_response_timeout = {{ .Values.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default 100 }}

{{- include "ini_sections.database" . }}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v3
auth_type = v3password
username = {{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
password = {{ .Values.global.glance_service_password | default "" | replace "$" "$$"}}
user_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
region_name = {{.Values.global.region}}
project_name = {{.Values.global.keystone_service_project |  default "service"}}
project_domain_name = {{.Values.global.keystone_service_domain | default "Default"}}
memcached_servers = {{include "memcached_host" .}}:{{.Values.global.memcached_port_public | default 11211}}
insecure = True

[paste_deploy]
flavor = keystone

[oslo_middleware]
enable_proxy_headers_parsing = true

[glance_store]
stores = {{ .Values.stores | default "file" | quote }}
default_store = {{ .Values.default_store | default "file" | quote }}

filesystem_store_datadir = /glance_store

{{- if .Values.swift.enabled }}
swift_store_region={{.Values.global.region}}
swift_store_auth_insecure = True
swift_store_create_container_on_put = True
{{- if .Values.swift.multi_tenant }}
swift_store_multi_tenant = True
default_swift_reference =
{{- else }}
default_swift_reference = swift-global
swift_store_config_file = /etc/glance/swift-store.conf
{{- end }}
{{- if .Values.swift.store_large_object_size }}
swift_store_large_object_size = {{.Values.swift.store_large_object_size}}
{{- end }}
swift_store_use_trusts=True
{{- end }}

[oslo_messaging_notifications]
driver = noop
