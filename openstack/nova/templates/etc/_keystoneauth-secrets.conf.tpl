[cinder]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}

[neutron]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}

[keystone_authtoken]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}

[placement]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}

[service_user]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}

[ironic]
username = nova
password = {{ required ".Values.global.nova_service_password is missing" .Values.global.nova_service_password | include "resolve_secret" }}
