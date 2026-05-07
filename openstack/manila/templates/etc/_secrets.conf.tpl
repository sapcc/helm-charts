{{- $vbase   := .Values.global.vaultBaseURL | required "missing value for .Values.global.vaultBaseURL" -}}
{{- $region  := .Values.global.region       | required "missing value for .Values.global.region"       -}}
[DEFAULT]
{{- include "ini_sections.default_transport_url" . }}

{{- include "ini_sections.database" . }}


[neutron]
username = {{ printf "%s/%s/manila/keystone-user/network/username" $vbase $region | replace "$" "$$"}}
password = {{ printf "%s/%s/manila/keystone-user/network/password" $vbase $region | replace "$" "$$"}}

[keystone_authtoken]
username = {{ printf "%s/%s/manila/keystone-user/service/username" $vbase $region | replace "$" "$$"}}
password = {{ printf "%s/%s/manila/keystone-user/service/password" $vbase $region | replace "$" "$$"}}


{{ include "ini_sections.audit_middleware_notifications" . }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}
