[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = true
create_isolated_networks = false
test_accounts_file = /etc/tempest/accounts.yaml
admin_username = admin
admin_password = {{ .Values.tempest.adminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest

[identity]
uri = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000,
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
endpoint_type = internalURL
v3_endpoint_type = internalURL
auth_version = v3
region = {{ .Values.global.region }}
catalog_type = identity
username = admin
password = {{ .Values.tempest.adminPassword }}
domain_name = tempest
default_domain_id = {{ .Values.tempest.domainId }}
admin_role = admin
admin_domain_scope = true
admin_domain_name = tempest
admin_username = admin
admin_password = {{ .Values.tempest.adminPassword }}
disable_ssl_certificate_validation = true

[identity-feature-enabled]
api_v3 = true
trust = true
domain_specific_drivers = true
security_compliance = false
{{- if not (eq .Values.release "newton") }}
project_tags = true
application_credentials = true
{{- end }}

[service_available]
cinder = False
glance = False
heat = False
ironic = False
neutron = False
nova = False
ahara = False
swift = False

[validation]
run_validation = False
