[DEFAULT]
debug = {{.Values.cluster_debug}}
rpc_backend = rabbit
auth_strategy = keystone
meter_dispatchers = http
event_dispatchers = http
default.log.levels = amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,oslo.messaging=DEBUG,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,urllib3.connectionpool=WARN,websocket=WARN,requests.packages.urllib3.util.retry=WARN,urllib3.util.retry=WARN,keystonemiddleware=DEBUG,routes.middleware=WARN,stevedore=WARN,taskflow=WARN,keystoneauth=DEBUG,oslo.cache=INFO,dogpile.core.dogpile=INFO,keystoneclient=WARN,ceilometer.agent.manager=DEBUG,kafka=DEBUG,kafka.conn=DEBUG,kafka.client=DEBUG

#[dispatcher_http]
#target = {{.Values.ceilometer_target}}
#target_username = {{.Values.ceilometer_target_username}}
#target_password = {{.Values.ceilometer_target_password}}
#target_clientcert = {{.Values.ceilometer_target_clientcert}}
#target_clientkey = {{.Values.ceilometer_target_clientkey}}
#event_target = {{.Values.ceilometer_event_target}}
#event_target_username = {{.Values.ceilometer_event_target_username}}
#event_target_password = {{.Values.ceilometer_event_target_password}}
#event_target_clientcert = {{.Values.ceilometer_event_target_clientcert}}
#event_target_clientkey = {{.Values.ceilometer_event_target_clientkey}}
#verify_ssl = {{.Values.ceilometer_verify_ssl}}
#timeout = {{.Values.ceilometer_timeout}}

#[collector]
#requeue_sample_on_dispatcher_error = True
#requeue_event_on_dispatcher_error = True

[oslo_messaging_rabbit]
rabbit_userid = {{.Values.rabbitmq_default_user}}
rabbit_password = {{.Values.rabbitmq_default_pass}}
rabbit_host = {{.Values.rabbitmq_host}}

[keystone_authtoken]
auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
auth_type = v3password
username = {{.Values.ceilometer_service_user}}
password = {{.Values.ceilometer_service_password}}
user_domain_name = {{.Values.keystone_service_domain}}
project_name = {{.Values.keystone_service_project}}
project_domain_name = {{.Values.keystone_service_domain}}

[notification]
store_events = True
#messaging_urls = rabbit://{{.Values.ceilometer_rabbitmq_default_user}}:{{.Values.ceilometer_rabbitmq_default_pass}}@ceilometer-rabbitmq:5672/
messaging_urls = rabbit://{{.Values.rabbitmq_default_user}}:{{.Values.rabbitmq_default_pass}}@{{.Values.rabbitmq_host}}:5672/

[oslo_messaging_rabbit]
# this varible is called rabbitmq and not rabbit like the other two, as the hostname will be built on kubernetes from the component name, which is rabbitmq and not rabbit
rabbit_host = ceilometer-rabbitmq
rabbit_userid = {{.Values.ceilometer_rabbitmq_default_user}}
rabbit_password = {{.Values.ceilometer_rabbitmq_default_pass}}

[publisher]
telemetry_secret = {{.Values.ceilometer_telemetry_secret}}

[service_credentials]
auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
auth_type = v3password
region_name = {{.Values.cluster_region}}
username = {{.Values.ceilometer_service_user}}
password = {{.Values.ceilometer_service_password}}
user_domain_name = {{.Values.keystone_service_domain}}
project_name = {{.Values.keystone_service_project}}
project_domain_name = {{.Values.keystone_service_domain}}
insecure = false
