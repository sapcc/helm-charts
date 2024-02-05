{{- define "tempest-base.extra_options" }}
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
endpoint_type = internal
v3_endpoint_type = internal
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

[image]
build_timeout=600

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ .Values.tempest_common.public_network_id }}
endpoint_type = internal
shared_physical_network= {{ .Values.tempest_common.shared_physical_network | default true }}
floating_network_name = FloatingIP-external-monsoon3-01
build_timeout=600
build_interval=20
subnet_id = a5703f23-ffcb-4ca7-9dfe-ab9861d91bf5

[network-feature-enabled]
ipv6 = False

[baremetal]
max_microversion = 1.78
# Driver to use for API tests for Queens and newer:
driver = fake-hardware


[compute]
# image_ref and image_ref_alt will be changed to the image-id during init-script as the image-id can change over time.
#image_ref = CHANGE_ME_IMAGE_REF
#image_ref_alt = CHANGEMEIMAGEREFALT
image_ref = 6f76b8c8-ca51-4f6a-a4bc-47893ae83dcf
image_ref_alt = 84f9f266-3f11-4447-ae6c-f7940b2f5eb1
endpoint_type = internal
v3_endpoint_type = internal
region = {{ .Values.global.region }}
flavor_ref = 20
flavor_ref_alt = 30
min_microversio = 2.1
max_microversion = latest
fixed_network_name = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.fixed_network_name }}
build_timeout=600

[compute-feature-enabled]
resize = True
unified_limits = False
cold_migration = False
live_migration = False
live_migrate_back_and_forth = False
vnc_console = False
vnc_server_header = WebSockify
serial_console = False
spice_console = False
attach_encrypted_volume = False

[share]
share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
alt_share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
admin_share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
run_revert_to_snapshot_tests = False
run_multiple_share_replicas_tests = False
run_share_group_tests = False
run_quota_tests = False
run_public_tests = False
create_networks_when_multitenancy_enabled = False
default_share_type_name = default
catalog_type = sharev2
max_api_microversion = 2.49
suppress_errors_in_cleanup = True
enable_ip_rules_for_protocols = nfs
enable_protocols = nfs
endpoint_type = internalURL
v3_endpoint_type = internalURL
region = {{ .Values.global.region }}

[validation]
image_ssh_user = ccloud
ssh_key_type = rsa

[volume]
catalog_type = volumev3
endpoint_type = internal
min_microversion = 3.0
max_microversion = latest
vendor_name = VMware
storage_protocol = vmdk
disk_format = vmdk
volume_size = 10
build_timeout=600
volume_type = vmware

[volume-feature-enabled]
backup = true

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

{{ end }}
