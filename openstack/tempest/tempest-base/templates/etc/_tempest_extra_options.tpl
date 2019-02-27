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

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = internal
v3_endpoint_type = internal
region = {{ .Values.global.region }}
default_domain_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.domainId }}
admin_domain_scope = True
disable_ssl_certificate_validation = True

[identity-feature-enabled]
domain_specific_drivers = True
project_tags = True
application_credentials = True

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.public_network_id }}
endpoint_type = internal

[network-feature-enabled]
ipv6 = false

[service_available]
manila = True
neutron = True
cinder = True
glance = True
nova = True
swift = True

{{ end }}