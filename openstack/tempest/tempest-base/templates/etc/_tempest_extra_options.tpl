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
admin_project_name = {{ (index .Values (print .Chart.Name | replace "-" "_")).tempest.admin_project_name }}

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = internal
v3_endpoint_type = internal
region = {{ .Values.global.region }}
default_domain_id = {{ .Values.tempest_common.domainId }}
admin_domain_scope = True
disable_ssl_certificate_validation = True

[identity-feature-enabled]
domain_specific_drivers = True
project_tags = True
application_credentials = True

[network]
project_network_cidr = 10.199.0.0/16
public_network_id = {{ .Values.tempest_common.public_network_id }}
endpoint_type = internal

[network-feature-enabled]
ipv6 = false

[compute]
# image_ref and image_ref_alt will be changed to the image-id during init-script as the image-id can change over time.
image_ref = CHANGE_ME_IMAGE_REF
image_ref_alt = CHANGE_ME_IMAGE_REF_ALT
endpoint_type = internal
v3_endpoint_type = internal
region = {{ .Values.global.region }}
flavor_ref = 20
flavor_ref_alt = 30
min_microversio = 2.1
max_microversion = latest

[compute-feature-enabled]
resize = true
cold_migration = false
live_migration = false
live_migrate_back_and_forth = false
vnc_console = true
vnc_server_header = WebSockify
serial_console = true
spice_console = true
attach_encrypted_volume = false

[service_available]
manila = True
neutron = True
cinder = True
glance = True
nova = True
swift = True

{{ end }}