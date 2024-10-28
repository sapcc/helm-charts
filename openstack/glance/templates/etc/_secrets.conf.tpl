[keystone_authtoken]
username = {{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
password = {{ required ".Values.global.glance_service_password is missing" .Values.global.glance_service_password }}

{{- include "ini_sections.database" . }}

{{- include "ini_sections.audit_middleware_notifications" . }}


{{- if .Values.swift.enabled }}
{{- if .Values.swift.multi_tenant }}
[glance_store]
swift_store_user = service:{{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
swift_store_key = {{ required ".Values.global.glance_service_password is missing" .Values.global.glance_service_password }}
{{- end }}
{{- end }}

{{- if and .Values.swift.enabled (not .Values.swift.multi_tenant)}}
[swift-global]
key = {{ required ".Values.global.glance_service_password is missing" .Values.global.glance_service_password }}
user = {{ .Values.swift.projectName }}:{{ .Values.global.glance_service_user | default "glance" | replace "$" "$$"}}
{{- end }}
