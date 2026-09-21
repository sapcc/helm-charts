{{- define "tempest-base.extra_options" }}
[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /{{ .Chart.Name }}-etc-secret/tempest_accounts.yaml
default_credentials_domain_name = {{ .Values.tempest_base.identity.default_credentials_domain_name }}
admin_project_name = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_project_name }}
admin_username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
admin_password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword | include "tempest-base.resolve_secret" }}
admin_domain_name = {{ .Values.tempest_base.identity.admin_domain_name }}
admin_domain_scope = True

[identity]
{{- if .Values.keystoneUrl }}
uri_v3 = {{ .Values.keystoneUrl }}
{{- else }}
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
{{- end }}
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
default_domain_id = {{ .Values.tempest_common.domainId }}
admin_domain_scope = False
disable_ssl_certificate_validation = True
auth_version = v3
username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
domain_name = {{ .Values.tempest_base.identity.domain_name }}
admin_role = {{ .Values.tempest_base.identity.admin_role }}
admin_domain_name = {{ .Values.tempest_base.identity.admin_domain_name }}
admin_username = {{ default "neutron-tempest-admin1" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_name }}
admin_password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword | include "tempest-base.resolve_secret"}}
catalog_type = identity
user_unique_last_password_count = {{ .Values.tempest_base.identity.user_unique_last_password_count }}
user_lockout_duration = {{ .Values.tempest_base.identity.user_lockout_duration }}
user_lockout_failure_attempts = {{ .Values.tempest_base.identity.user_lockout_failure_attempts }}

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
project_network_cidr = {{ .Values.tempest_base.network.project_network_cidr }}
public_network_id = {{ .Values.tempest_common.public_network_id }}
endpoint_type = public
shared_physical_network= {{ .Values.tempest_common.shared_physical_network | default true }}
floating_network_name = {{ .Values.tempest_base.network.floating_network_name }}
build_timeout=600
build_interval=20
subnet_id = {{ .Values.tempest_base.network.subnet_id }}

[network-feature-enabled]
ipv6 = False

[neutron_plugin_options]
max_mtu = {{ .Values.tempest_base.network.max_mtu }}

[baremetal]
max_microversion = {{ .Values.tempest_base.baremetal.max_microversion }}
# Driver to use for API tests for Queens and newer:
driver = {{ .Values.tempest_base.baremetal.driver }}


[compute]
image_ref = {{ .Values.tempest_base.compute.image_ref }}
image_ref_alt = {{ .Values.tempest_base.compute.image_ref_alt }}
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
flavor_ref = {{ .Values.tempest_base.compute.flavor_ref }}
flavor_ref_alt = {{ .Values.tempest_base.compute.flavor_ref_alt }}
min_microversion = {{ .Values.tempest_base.compute.min_microversion }}
max_microversion = latest
fixed_network_name = {{ default "" (index .Values (print .Chart.Name | replace "-" "_")).tempest.fixed_network_name }}
build_timeout=600
compute_volume_common_az = {{ .Values.tempest_base.compute.compute_volume_common_az }}

[compute-feature-enabled]
resize = True
unified_limits = False
cold_migration = False
live_migration = False
live_migrate_back_and_forth = False
vnc_console = False
vnc_server_header = {{ .Values.tempest_base.compute.vnc_server_header }}
serial_console = False
spice_console = False
attach_encrypted_volume = False

[share]
share_network_id = {{ default "" (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
alt_share_network_id = {{ default "" (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
admin_share_network_id = {{ default "" (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
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
endpoint_type = publicURL
v3_endpoint_type = publicURL
region = {{ .Values.global.region }}

[validation]
image_ssh_user = {{ .Values.tempest_base.validation.image_ssh_user }}
ssh_key_type = rsa

[volume]
catalog_type = volumev3
endpoint_type = public
min_microversion = 3.0
max_microversion = latest
vendor_name = {{ .Values.tempest_base.volume.vendor_name }}
storage_protocol = {{ .Values.tempest_base.volume.storage_protocol }}
disk_format = {{ .Values.tempest_base.volume.disk_format }}
volume_size = {{ .Values.tempest_base.volume.volume_size }}
build_timeout=600
volume_type = {{ .Values.tempest_base.volume.volume_type }}

[volume-feature-enabled]
backup = {{ .Values.tempest_base.volume_feature_enabled.backup }}

[service_available]
manila = {{ .Values.tempest_base.service_available.manila }}
neutron = {{ .Values.tempest_base.service_available.neutron }}
cinder = {{ .Values.tempest_base.service_available.cinder }}
glance = {{ .Values.tempest_base.service_available.glance }}
nova = {{ .Values.tempest_base.service_available.nova }}
swift = {{ .Values.tempest_base.service_available.swift }}
designate = {{ .Values.tempest_base.service_available.designate }}
ironic = {{ .Values.tempest_base.service_available.ironic }}
barbican = {{ .Values.tempest_base.service_available.barbican }}
keystone = {{ .Values.tempest_base.service_available.keystone }}
octavia = {{ .Values.tempest_base.service_available.octavia }}

[dns]
nameservers = {{ .Values.tempest_base.dns.nameservers }}

{{ end }}
