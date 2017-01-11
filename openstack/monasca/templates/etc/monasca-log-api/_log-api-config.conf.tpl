[DEFAULT]
{{if eq .Values.monasca_log_api_loglevel "DEBUG" }}
general_log             = 1
{{else}}
general_log             = 0
{{end}}

[service]
region = {{.Values.cluster_region}}
max_log_size = 1048576

#[monitoring]
#statsd_host = 127.0.0.1
#statsd_port = 8125
#statsd_buffer = 50

[log_publisher]
topics = log
kafka_url = kafka:{{.Values.monasca_kafka_port_internal}}

[keystone_authtoken]
# TODO: @Olaf, what is this?? auth_uri or auth_url? and why ADMIN port? please add a comment. I just found out that it does not work w/o auth_uri
auth_uri = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}
auth_url = {{.Values.keystone_api_endpoint_protocol_admin}}://{{.Values.keystone_api_endpoint_host_admin}}:{{.Values.keystone_api_port_admin}}/v3
auth_type = v3password
username = {{.Values.monasca_api_username}}
password = {{.Values.monasca_api_password}}
user_domain_name = {{.Values.monasca_api_project_domain_name}}
project_name = {{.Values.monasca_api_project_name}}
project_domain_name = {{.Values.monasca_api_project_domain_name}}

insecure = false
cafile = /etc/ssl/certs/ca-certificates.crt
certfile =
keyfile =
memcached_servers = 127.0.0.1:11211
token_cache_time = 900

[kafka_healthcheck]
kafka_url = kafka:{{.Values.monasca_kafka_port_internal}}
kafka_topics = log
consumer_id = KAFKA_CONSUMER_ID
client_id = monasca-log-api

[roles_middleware]
path = /v2.0/log
path = /v3.0/logs
default_roles = monasca-user
agent_roles = monasca-agent

[dispatcher]
logs = monasca_log_api.reference.v2.logs:Logs
logs_v3 = monasca_log_api.reference.v3.logs:Logs
versions = monasca_log_api.reference.versions:Versions
healthchecks = monasca_log_api.reference.healthchecks:HealthChecks
