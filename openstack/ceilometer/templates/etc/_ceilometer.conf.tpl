[DEFAULT]
debug = {{.Values.cluster_debug}}
rpc_backend = rabbit
auth_strategy = keystone
meter_dispatchers = http
event_dispatchers = http
default.log.levels = amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,oslo.messaging=DEBUG,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,urllib3.connectionpool=WARN,websocket=WARN,requests.packages.urllib3.util.retry=WARN,urllib3.util.retry=WARN,keystonemiddleware=DEBUG,routes.middleware=WARN,stevedore=WARN,taskflow=WARN,keystoneauth=DEBUG,oslo.cache=INFO,dogpile.core.dogpile=INFO,keystoneclient=WARN,ceilometer.agent.manager=DEBUG

[dispatcher_http]
#target=https://apache-https/
target = {{.Values.ceilometer_target}}
target_username = {{.Values.ceilometer_target_username}}
target_password = {{.Values.ceilometer_target_password}}
target_clientcert = {{.Values.ceilometer_target_clientcert}}
target_clientkey = {{.Values.ceilometer_target_clientkey}}
#event_target = https://apache-https/
event_target = {{.Values.ceilometer_event_target}}
event_target_username = {{.Values.ceilometer_event_target_username}}
event_target_password = {{.Values.ceilometer_event_target_password}}
event_target_clientcert = {{.Values.ceilometer_event_target_clientcert}}
event_target_clientkey = {{.Values.ceilometer_event_target_clientkey}}
#verify_ssl = True
verify_ssl = {{.Values.ceilometer_verify_ssl}}
#timeout = 10
timeout = {{.Values.ceilometer_timeout}}

[collector]
requeue_sample_on_dispatcher_error = True
requeue_event_on_dispatcher_error = True

[oslo_messaging_rabbit]
rabbit_userid = {{.Values.rabbitmq_default_user}}
rabbit_password = {{.Values.rabbitmq_default_pass}}
rabbit_host = {{.Values.rabbitmq_host}}

[keystone_authtoken]
auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
#identity_uri = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}
auth_type = v3password
username = {{.Values.ceilometer_service_user}}
password = {{.Values.ceilometer_service_password}}
user_domain_name = {{.Values.keystone_service_domain}}
project_name = {{.Values.keystone_service_project}}
project_domain_name = {{.Values.keystone_service_domain}}
## is the below still needed or is this old keystone v2 stuff?
#admin_user = {{.Values.ceilometer_service_user}}
#admin_password = {{.Values.ceilometer_service_password}}
#admin_tenant_name = {{.Values.keystone_service_project}}
#cafile = /etc/ssl/certs/ca-certificates.crt

[notification]
store_events = True
messaging_urls = rabbit://{{.Values.ceilometer_rabbitmq_default_user}}:{{.Values.ceilometer_rabbitmq_default_pass}}@ceilometer-rabbitmq:5672/
messaging_urls = rabbit://{{.Values.rabbitmq_default_user}}:{{.Values.rabbitmq_default_pass}}@{{.Values.rabbitmq_host}}:5672/

[oslo_messaging_rabbit]
# this varrible is called rabbitmq and not rabbit like the other two, as the hostname will be built on kubernetes from the component name, which is rabbitmq and not rabbit
rabbit_host = ceilometer-rabbitmq
rabbit_userid = {{.Values.ceilometer_rabbitmq_default_user}}
rabbit_password = {{.Values.ceilometer_rabbitmq_default_pass}}

[publisher]
telemetry_secret = {{.Values.ceilometer_telemetry_secret}}

[service_credentials]
auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
# auth_plugin = v3password - deprecated, should be deleted soon
auth_type = v3password
region_name = {{.Values.cluster_region}}
username = {{.Values.ceilometer_service_user}}
password = {{.Values.ceilometer_service_password}}
user_domain_name = {{.Values.keystone_service_domain}}
project_name = {{.Values.keystone_service_project}}
project_domain_name = {{.Values.keystone_service_domain}}
## some of them might be no longer used keystone v2 values- we should check this
#os_username = {{.Values.ceilometer_service_user}}
#os_password = {{.Values.ceilometer_service_password}}
#os_tenant_name = {{.Values.keystone_service_project}}
#os_auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
#os_region_name = {{.Values.cluster_region}}
#auth_type = password
#cafile = /etc/ssl/certs/ca-certificates.crt
# insecure is required, as the keystone middleware is hardcoded to connect to the admin port, which is ingres https, which is sni and the python code seems to have problems with sni https
# hardcoded admin port according to rudolf: https://github.com/openstack/keystonemiddleware/blob/stable/mitaka/keystonemiddleware/auth_token/__init___py#L1056
insecure = false
## use the internal interface (http in our case) when connecting to keystone to avoid https cert trouble with python/ingres/sni
#interface = internal
