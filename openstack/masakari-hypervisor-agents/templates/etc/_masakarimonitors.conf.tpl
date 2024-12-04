[api]
region = {{ .Values.global.region }}
api_interface = public
auth_url = https://identity-3.{{ .Values.global.region }}.cloud.sap/v3
project_name = service
project_domain_name = default
username = masakari
user_domain_name = default
password = {{"{{"}} resolve "vault+kvv2:///secrets/{{ .Values.global.region }}/masakari/keystone-user/service/password" {{"}}"}}

[introspectiveinstancemonitor]
qemu_guest_agent_sock_path = /var/lib/libvirt/qemu/.*instance.*\.sock
