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
max_pool_size = {{ .Values.max_pool_size | default 5 }}
max_overflow = {{ .Values.max_overflow | default 10 }}

[database]
connection = postgresql://{{ .Values.postgresql.dbUser }}:{{ .Values.postgresql.dbPassword }}@{{include "db_host" .}}:5432/{{.Values.postgresql.postgresDatabase}}

[keystone_authtoken]
auth_uri = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}
auth_url = {{.Values.global.keystone_api_endpoint_protocol_admin | default "http"}}://{{include "keystone_api_endpoint_host_admin" .}}:{{ .Values.global.keystone_api_port_admin | default 35357}}/v3
auth_type = v3password
username = {{ .Values.keystone.username | default "glance" | quote}}
password = {{ .Values.keystone.password }}
{{- if .Values.keystone.userDomainName }}
user_domain_name = {{ .Values.keystone.userDomainName }}
{{- end }}
{{- if .Values.keystone.userDomainId }}
user_domain_id = {{ .Values.keystone.userDomainId }}
{{- end }}
{{- if .Values.keystone.projectName }}
project_name = {{ .Values.keystone.projectName }}
{{- end }}
{{- if .Values.keystone.projectDomainName }}
project_domain_name = {{ .Values.keystone.projectDomainName }}
{{- end }}
{{- if .Values.keystone.projectDomainId }}
project_domain_id = {{ .Values.keystone.projectDomainId }}
{{- end }}
{{- if .Values.memcached }}
memcache_servers = {{include "memcached_host" .}}:{{.Values.memcached.port}}
{{- end}}
insecure = True

[paste_deploy]
flavor = keystone

[oslo_middleware]
enable_proxy_headers_parsing = true

[glance_store]
stores = {{ .Values.stores | default "file" | quote }}
default_store = {{ .Values.default | default "file" | quote }}

filesystem_store_datadir = /glance_store

{{- if .Values.swift.enabled }}
swift_store_region={{.Values.global.region}}
swift_store_auth_insecure = True
swift_store_create_container_on_put = True
swift_store_multi_tenant = {{.Values.store.swift.multi_tenant}}
default_swift_reference = swift-global
swift_store_config_file=/etc/glance/swift-store.conf
swift_store_use_trusts=True
{{- end }}

[oslo_messaging_notifications]
driver = noop
