{{- if and .Values.swift.enabled (not .Values.swift.multi_tenant)}}
[swift-global]
auth_version = 3
project_domain_name = {{.Values.swift.projectDomainName}}
user_domain_name = {{.Values.swift.userDomainName}}
auth_address = {{.Values.global.keystone_api_endpoint_protocol_internal | default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000}}/v3
key = {{ .Values.global.glance_service_password | default (tuple . .Values.global.glance_service_user | include "identity.password_for_user") | replace "$" "$$" }}
user = {{ .Values.swift.projectName }}:{{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
{{- end }}
