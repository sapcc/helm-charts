[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = False
create_isolated_networks = False
test_accounts_file = /glance-etc/tempest_accounts.yaml
admin_username = admin
admin_password = {{ .Values.tempestAdminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

[image]
#catalog_type = image
region = {{ .Values.global.region }}
endpoint_type = internalURL
# http accessible image (string value)
#http_image = http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-uec.tar.gz

# Timeout in seconds to wait for an image to become available.
# (integer value)
#build_timeout = 300

# Time in seconds between image operation status checks. (integer value)
#build_interval = 1

# A list of image's container formats users can specify. (list value)
#container_formats = ami,ari,aki,bare,ovf,ova

# A list of image's disk formats users can specify. (list value)
#disk_formats = ami,ari,aki,vhd,vmdk,raw,qcow2,vdi,iso,vhdx

[image-feature-enabled]
api_v2 = true

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
glance = True
neutron = False
cinder = False
nova = False
swift = False
