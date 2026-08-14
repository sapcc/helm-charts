# secret.conf
[DEFAULT]
{{ include "ini_sections.default_transport_url" . }}

[nova]
username = {{ include "resolve_secret" ( .Values.global.neutron_service_user | default "neutron") }}
password = {{ include "resolve_secret" ( .Values.global.neutron_service_password | default "vault+kvv2:///secrets/{{ required .Values.global.region '.Values.global.region required' }}/neutron/keystone-user/service/password" ) }}

[keystone_authtoken]
username = {{ include "resolve_secret" ( .Values.global.neutron_service_user | default "neutron") }}
password = {{ include "resolve_secret" ( .Values.global.neutron_service_password | default "vault+kvv2:///secrets/{{ required .Values.global.region '.Values.global.region required' }}/neutron/keystone-user/service/password" ) }}
