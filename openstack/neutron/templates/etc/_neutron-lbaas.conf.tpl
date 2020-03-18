[DEFAULT]
log_config_append = /etc/neutron/logging.conf

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 5 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}

[service_providers]
{{- if .Values.octavia }}
service_provider = LOADBALANCERV2:Octavia:neutron_lbaas.drivers.octavia.driver.OctaviaDriver:default
{{- else }}
service_provider = LOADBALANCERV2:F5Networks:neutron_lbaas.drivers.f5.driver_v2.F5LBaaSV2Driver:default
{{- end }}

[service_auth]
auth_url = {{.Values.global.keystone_api_endpoint_protocol_internal| default "http"}}://{{include "keystone_api_endpoint_host_internal" .}}:{{ .Values.global.keystone_api_port_internal | default 5000 }}/v3
admin_project_domain= {{.Values.global.keystone_service_domain | default "Default"}}
admin_user_domain= {{.Values.global.keystone_service_domain | default "Default"}}
admin_tenant_name =  {{.Values.global.keystone_service_project | default "service"}}
admin_user = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$"}}
admin_password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$"}}
region={{.Values.global.region}}
service_name=lbaas
auth_version = 3
insecure=True

[quotas]
quota_loadbalancer=0
quota_listener=0
quota_pool=0
quota_member=40000
quota_healthmonitor=0

{{- include "ini_sections.audit_middleware_notifications" . }}
