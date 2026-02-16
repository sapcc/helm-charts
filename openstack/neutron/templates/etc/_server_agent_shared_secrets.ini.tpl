[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[keystone_authtoken]
username = {{ .Values.global.neutron_service_user | default "neutron" | include "resolve_secret" }}
password = {{ .Values.global.neutron_service_password | default "" | include "resolve_secret" }}

{{- if .Values.osprofiler.enabled }}
{{- include "osprofiler" . }}
{{- end }}

{{- if .Values.f5.notifications.enabled }}
[ml2_f5_notifications]
topics = notifications
driver = {{ .Values.f5.notifications.driver }}
transport_url = rabbit://{{ include "resolve_secret_urlquery" .Values.f5.notifications.user }}:{{ include "resolve_secret_urlquery" .Values.f5.notifications.password }}@{{ .Values.f5.notifications.host }}:{{ .Values.f5.notifications.port | default 5672 }}/{{ .Values.f5.notifications.virtual_host | default "" }}
{{- end }}