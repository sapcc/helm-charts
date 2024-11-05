# secret.conf
[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[nova]
username = {{ include "resolve_secret" .Values.global.neutron_service_user }}
password = {{ include "resolve_secret" .Values.global.neutron_service_password }}

[keystone_authtoken]
username = {{ include "resolve_secret" .Values.global.neutron_service_user }}
password = {{ include "resolve_secret" .Values.global.neutron_service_password }}
