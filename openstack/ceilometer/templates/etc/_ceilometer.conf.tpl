[DEFAULT]
debug = {{.Values.cluster_debug}}
auth_strategy = keystone
meter_dispatchers = http
event_dispatchers = http
default.log.levels = amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,oslo.messaging=DEBUG,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,urllib3.connectionpool=WARN,websocket=WARN,requests.packages.urllib3.util.retry=WARN,urllib3.util.retry=WARN,keystonemiddleware=DEBUG,routes.middleware=WARN,stevedore=WARN,taskflow=WARN,keystoneauth=DEBUG,oslo.cache=INFO,dogpile.core.dogpile=INFO,keystoneclient=WARN,ceilometer.agent.manager=DEBUG,kafka=DEBUG,kafka.conn=DEBUG,kafka.client=DEBUG

[oslo_messaging_notifications]
transport_url = kafka://{{.Values.monasca_kafka_hostname}}:{{.Values.monasca_kafka_port_internal}}

[oslo_messaging_kafka]

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
# Notifications from ceilometer-central polling
messaging_urls = kafka://{{.Values.monasca_kafka_hostname}}:{{.Values.monasca_kafka_port_internal}}
# Notifications from OpenStack core components
messaging_urls = rabbit://{{.Values.rabbitmq_default_user}}:{{.Values.rabbitmq_default_pass}}@{{.Values.rabbitmq_host}}:5672/

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
