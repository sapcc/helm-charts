# metadata_agent.ini
[DEFAULT]
debug = {{.Values.debug}}

#endpoint_type = internalURL

nova_metadata_ip = {{include "nova_api_endpoint_host_public" .}}
nova_metadata_host = {{include "nova_api_endpoint_host_public" .}}
nova_metadata_protocol = {{.Values.global.nova_api_endpoint_protocol_external | default "https"}}
nova_metadata_port = {{.Values.global.nova_metadata_port_external | default 443}}

{{- if .Values.agent.multus | default false }}
metadata_proxy_socket = /run/metadata_proxy/metadata_proxy
{{- else }}
metadata_proxy_socket = /run/metadata_proxy
{{- end }}

rpc_response_timeout = {{ .Values.metadata_rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 5 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}
metadata_workers = {{ .Values.agent.metadata_workers | default .Values.global.metadata_workers | default 1 }}

[cache]
backend = dogpile.cache.memory
expiration_time = 5
