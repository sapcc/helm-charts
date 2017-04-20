[DEFAULT]
debug = {{.Values.cluster_debug}}
auth_strategy = keystone
default_log_levels = amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,oslo.messaging=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,urllib3.connectionpool=WARN,websocket=WARN,requests.packages.urllib3.util.retry=WARN,urllib3.util.retry=WARN,keystonemiddleware=DEBUG,routes.middleware=WARN,stevedore=WARN,taskflow=WARN,keystoneauth=DEBUG,oslo.cache=INFO,dogpile.core.dogpile=INFO,keystoneclient=WARN,swiftclient=INFO
#,ceilometer.publisher=DEBUG,ceilometer.publisher.http=DEBUG,ceilometer.publisher.kafka_broker=DEBUG,ceilometer.publisher.messaging=DEBUG,oslo.messaging=INFO

# oslo_messaging and publisher_notifier sections are only used with the notifier:// publisher
# [oslo_messaging_notifications]
# driver = messaging
# transport_url = kafka://{{.Values.monasca_kafka_hostname}}:{{.Values.monasca_kafka_port_internal}}
#
# [publisher_notifier]
# # The topic that ceilometer uses for event notifications. (string value)
# # the actual kafka topic will be "events-cadf.sample" if the notifier:// publisher is used
# event_topic = events-cadf

[keystone_authtoken]
auth_url = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}/v3
auth_type = v3password
username = {{.Values.ceilometer_service_user}}
password = {{.Values.ceilometer_service_password}}
user_domain_name = {{.Values.keystone_service_domain}}
project_name = {{.Values.keystone_service_project}}
project_domain_name = {{.Values.keystone_service_domain}}

[event]
definitions_cfg_file = event_definitions.yaml
drop_unmatched_notifications = False
store_raw = info

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
