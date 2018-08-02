[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /manila-etc/tempest_accounts.yaml
admin_username = admin
admin_password = {{ .Values.tempestAdminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

[share]
run_revert_to_snapshot_tests = {{ .Values.tempest.revert_to_snapshot_tests }}
run_multiple_share_replicas_tests = False
run_share_group_tests = False
default_share_type_name = default
catalog_type = sharev2
max_api_microversion = 2.43
suppress_errors_in_cleanup = True
enable_ip_rules_for_protocols = ['nfs']
# no cifs, don't even go there
enable_protocols = ['nfs']
endpoint_type = internalURL
v3_endpoint_type = internalURL
region = {{ .Values.global.region }}

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = internalURL
v3_endpoint_type = internalURL
region = {{ .Values.global.region }}
default_domain_id = {{ .Values.tempest.domainId }}
admin_domain_scope = True
disable_ssl_certificate_validation = True

[identity-feature-enabled]
domain_specific_drivers = True
project_tags = True
application_credentials = True

[service_available]
cinder = False
glance = False
neutron = True
nova = False
swift = False
