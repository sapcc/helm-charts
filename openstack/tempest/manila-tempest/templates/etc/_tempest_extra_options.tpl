[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /{{ .Chart.Name }}-etc/tempest_accounts.yaml
admin_username = admin
admin_password = {{ required "A valid .Values.tempestAdminPassword required!" .Values.tempestAdminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

[share]
share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.share_network_id }}
alt_share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.alt_share_network_id }}
admin_share_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_share_network_id }}
run_revert_to_snapshot_tests = {{ default false (index .Values (print .Chart.Name | replace "-" "_")).tempest.run_revert_to_snapshot_tests }}
run_multiple_share_replicas_tests = True
run_share_group_tests = False
run_quota_tests = False
run_public_tests = False
run_admin_project_member_client_tests = False
run_security_service_backend_tests = True
multitenancy_enabled = True
create_networks_when_multitenancy_enabled = False
default_share_type_name = default
catalog_type = sharev2
max_api_microversion = 2.65
suppress_errors_in_cleanup = True
enable_ip_rules_for_protocols = nfs
enable_protocols = nfs
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = public
v3_endpoint_type = public
region = {{ .Values.global.region }}
default_domain_id = {{ .Values.tempest_common.domainId }}
admin_domain_scope = True
disable_ssl_certificate_validation = True
auth_version = v3

[identity-feature-enabled]
domain_specific_drivers = True
project_tags = True
application_credentials = True
api_v2 = False
api_v2_admin = False
api_v3 = True
trust = True
security_compliance = True

[service_available]
manila = True
neutron = False
cinder = False
glance = False
nova = False
swift = False
designate = False
ironic = False
barbican = False
keystone = True
