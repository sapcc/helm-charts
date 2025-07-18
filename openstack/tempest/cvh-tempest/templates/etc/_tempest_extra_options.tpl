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
admin_domain_scope = False
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

[image]
build_timeout=10800

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ .Values.tempest_common.public_network_id }}
endpoint_type = public
shared_physical_network= {{ .Values.tempest_common.shared_physical_network | default true }}
floating_network_name = FloatingIP-external-monsoon3-01
build_timeout=600
build_interval=20
subnet_id = a5703f23-ffcb-4ca7-9dfe-ab9861d91bf5

[network-feature-enabled]
ipv6 = False

[compute]
image_ref = ed8dd007-de9c-4456-91d5-6965c6c12b61
image_ref_alt = ed8dd007-de9c-4456-91d5-6965c6c12b61
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
flavor_ref = 200403
flavor_ref_alt = 200408
min_microversio = 2.1
max_microversion = latest
fixed_network_name = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.fixed_network_name }}
build_timeout=600
compute_volume_common_az=qa-de-1b
ccloud_compute_kvm_flavor_disk_ref = 100021

[compute-feature-enabled]
resize = True
unified_limits = False
cold_migration = False
live_migration = False
live_migrate_back_and_forth = False
vnc_console = True
vnc_server_header = WebSockify
serial_console = False
spice_console = False
attach_encrypted_volume = False
console_output = False
rescue = False
snapshot = False
shelve = False

[validation]
image_ssh_user = cirros
image_alt_ssh_user = ccloud

[volume]
catalog_type = volumev3
endpoint_type = public
min_microversion = 3.0
max_microversion = latest
volume_size = 10
build_timeout=600
volume_type = nfs

[volume-feature-enabled]
backup = true

[service_available]
manila = False
neutron = True
cinder = True
glance = True
nova = True
swift = False
designate = False
ironic = False
barbican = False
keystone = False
octavia = False
