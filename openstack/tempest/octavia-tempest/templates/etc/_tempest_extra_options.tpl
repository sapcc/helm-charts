[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /{{ .Chart.Name }}-etc/tempest_accounts.yaml
default_credentials_domain_name = tempest
admin_project_name = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_project_name }}
admin_username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
admin_password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword }}
admin_domain_name = tempest
admin_domain_scope = True

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
default_domain_id = {{ .Values.tempest_common.domainId }}
admin_domain_scope = True
disable_ssl_certificate_validation = True
auth_version = v3
username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword }}
domain_name = tempest
admin_role = admin
admin_domain_name = tempest
admin_username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
admin_password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword }}
catalog_type = identity
user_unique_last_password_count = 5
user_lockout_duration = 300
user_lockout_failure_attempts = 5

[identity-feature-enabled]
domain_specific_drivers = True
project_tags = True
application_credentials = True
api_v2 = False
api_v2_admin = False
api_v3 = True
trust = True
security_compliance = True

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ .Values.tempest_common.public_network_id }}
subnet_id = a5703f23-ffcb-4ca7-9dfe-ab9861d91bf5
endpoint_type = public
shared_physical_network= {{ .Values.tempest_common.shared_physical_network | default true }}

[network-feature-enabled]
ipv6 = false

[baremetal]
min_microversion = 1.46
max_microversion = 1.46
# Driver to use for API tests for Queens and newer:
driver = fake-hardware

[compute]
# image_ref and image_ref_alt will be changed to the image-id during init-script as the image-id can change over time.
#image_ref = CHANGE_ME_IMAGE_REF
#image_ref_alt = CHANGEMEIMAGEREFALT
image_ref = 84f9f266-3f11-4447-ae6c-f7940b2f5eb1
image_ref_alt = 84f9f266-3f11-4447-ae6c-f7940b2f5eb1
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
flavor_ref = 20
flavor_ref_alt = 30
min_microversio = 2.1
max_microversion = latest
fixed_network_name = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.fixed_network_name }}

[compute-feature-enabled]
resize = true
cold_migration = false
live_migration = false
live_migrate_back_and_forth = false
vnc_console = true
vnc_server_header = WebSockify
attach_encrypted_volume = false

[validation]
image_ssh_user = ccloud
ssh_key_type = rsa

[volume]
catalog_type = volumev3
endpoint_type = public
min_microversion = 3.0
max_microversion = latest
vendor_name = VMware
storage_protocol = vmdk
disk_format = vmdk
volume_size = 3

[volume-feature-enabled]
backup = true

[load_balancer]
admin_role = admin
octavia_svc_username = admin
member_role = admin
observer_role = admin
global_observer_role = admin
provider = f5
RBAC_test_type = none
test_with_ipv6 = False
test_server_path = /rally/xrally_openstack/octavia-tempest-plugin/test_server.bin
create_security_group = True
scp_connection_timeout = 60
build_timeout=600
enabled_provider_drivers=noop_driver: 'The No-Op driver.',f5: 'F5 BigIP driver.',F5Networks: 'F5 BigIP driver'

[service_available]
manila = True
neutron = True
cinder = True
glance = True
nova = True
swift = True
designate = True
ironic = True
barbican = True
keystone = True
octavia = True
