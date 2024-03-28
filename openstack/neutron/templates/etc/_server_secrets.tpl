[nova]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}

[designate]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}

[keystone_authtoken]
username = {{ .Values.global.neutron_service_user | default "neutron" | replace "$" "$$" }}
password = {{ .Values.global.neutron_service_password | default "" | replace "$" "$$" }}
