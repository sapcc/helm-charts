[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /neutron-etc-tempest/tempest_accounts.yaml
admin_username = neutron-tempestadmin1
admin_password = {{ .Values.tempestAdminPassword }}
admin_project_name = neutron-tempest-admin1
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

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

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ .Values.tempest.public_network_id }}

[network-feature-enabled]
ipv6 = false

[service_available]
manila = False
neutron = True
cinder = False
glance = False
nova = False
swift = False
