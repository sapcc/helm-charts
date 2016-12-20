{{- define "monasca_health_healthcheck_conf_tpl" -}}
export OS_REGION_NAME={{.Values.cluster_region}}
export OS_USER_DOMAIN_NAME={{.Values.keystone_service_domain}}
export OS_PROJECT_NAME={{.Values.monasca_admin_project_name}}
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL={{.Values.keystone_api_endpoint_protocol_public}}://{{.Values.keystone_api_endpoint_host_public}}:{{.Values.keystone_api_port_public}}/v3
export OS_USERNAME=concourse
export OS_PASSWORD={{.Values.concourse_password}}
# needed for the official monasca cli
#export OS_DOMAIN_NAME={{.Values.monasca_admin_project_domain_name}}
# hardcode this for now, as the abobe line does not seem to expand properly
export OS_DOMAIN_NAME=ccadmin
# needed for our monasca cli
#export OS_PROJECT_DOMAIN_NAME={{.Values.monasca_admin_project_domain_name}}
# hardcode this for now, as the abobe line does not seem to expand properly
export OS_PROJECT_DOMAIN_NAME=ccadmin
export OS_CACERT=/etc/ssl/certs/ca-certificates.crt
# explicitely specify the monasca-api url, so that we test the public url including the ingress
export MONASCA_API_URL={{.Values.monasca_api_endpoint_protocol_public}}://{{.Values.monasca_api_endpoint_host_public}}:{{.Values.monasca_api_port_public}}/v2.0
{{ end }}
