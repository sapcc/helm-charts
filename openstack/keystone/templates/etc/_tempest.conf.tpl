[DEFAULT]
debug = True
use_stderr = True
rally_debug = True

[auth]
use_dynamic_credentials = false
test_accounts_file = /etc/tempest/accounts.yaml
default_credentials_domain_name = tempest
admin_username = admin
admin_password = {{ required "A valid .Values.tempest.adminPassword required!" .Values.tempest.adminPassword }}
admin_project_name = admin
admin_domain_name = tempest
create_isolated_networks = false

[identity]
uri_v3 = http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3
v3_endpoint_type = internal
auth_version = v3
region = {{ .Values.global.region }}
username = admin
password = {{ required "A valid .Values.tempest.adminPassword required!" .Values.tempest.adminPassword }}
domain_name = tempest
default_domain_id = {{ .Values.tempest.domainId }}
admin_role = admin
{{- if eq .Values.api.policy "json" }}
admin_domain_scope = true
{{- end }}
catalog_type = identity
disable_ssl_certificate_validation = true
user_unique_last_password_count = 5
user_lockout_duration = 300
user_lockout_failure_attempts = 5

[identity-feature-enabled]
api_v2 = false
api_v2_admin = false
api_v3 = true
trust = true
domain_specific_drivers = true
security_compliance = true
project_tags = true
application_credentials = true
immutable_user_source = false

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
