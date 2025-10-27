{{- if and .Values.swift.enabled (not .Values.swift.multi_tenant)}}
[swift-global]
auth_version = 3
project_domain_name = {{.Values.swift.projectDomainName}}
user_domain_name = {{.Values.swift.userDomainName}}
auth_address = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
{{- end }}
