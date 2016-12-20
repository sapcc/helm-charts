{{- define "monasca_api_api_config_conf_tpl" -}}
[DEFAULT]
# Show debugging output in logs (sets DEBUG log level output)
{% if cluster_config['monasca.api.loglevel'] == 'DEBUG' %}
debug = true
{% else %}
debug = false
{% endif %}

# Identifies the region that the Monasca API is running in.
region = {{.Values.cluster_region}}

# Dispatchers to be loaded to serve restful APIs
[dispatcher]
versions = monasca_api.v2.reference.versions:Versions
version_2_0 = monasca_api.v2.reference.version_2_0:Version2
metrics = monasca_api.v2.reference.metrics:Metrics
metrics_measurements = monasca_api.v2.reference.metrics:MetricsMeasurements
metrics_statistics = monasca_api.v2.reference.metrics:MetricsStatistics
metrics_names = monasca_api.v2.reference.metrics:MetricsNames
alarm_definitions = monasca_api.v2.reference.alarm_definitions:AlarmDefinitions
alarms = monasca_api.v2.reference.alarms:Alarms
alarms_count = monasca_api.v2.reference.alarms:AlarmsCount
alarms_state_history = monasca_api.v2.reference.alarms:AlarmsStateHistory
notification_methods = monasca_api.v2.reference.notifications:Notifications
dimension_values = monasca_api.v2.reference.metrics:DimensionValues
dimension_names = monasca_api.v2.reference.metrics:DimensionNames
notification_method_types = monasca_api.v2.reference.notificationstype:NotificationsType

# no yet available
#[monitoring]
#statsd_host = localhost
#statsd_port = 8125
#statsd_buffer = 50

[security]
# The roles that are allowed full access to the API.
default_authorized_roles = monasca-user

# The roles that are allowed to only POST metrics to the API. This role would be used by the Monasca Agent.
agent_authorized_roles = monasca-agent

# The roles that are allowed to only GET metrics from the API.
read_only_authorized_roles = monasca-viewer

# The roles that are allowed to access the API on behalf of another tenant.
# For example, a service can POST metrics to another tenant if they are a member of the "delegate" role.
delegate_authorized_roles = monasca-delegate

[messaging]
# The message queue driver to use
driver = monasca_api.common.messaging.kafka_publisher:KafkaPublisher

[repositories]
# The driver to use for the metrics repository
# Switches depending on backend database in use. Influxdb or Cassandra.
metrics_driver = monasca_api.common.repositories.influxdb.metrics_repository:MetricsRepository
#metrics_driver = monasca_api.common.repositories.cassandra.metrics_repository:MetricsRepository

# The driver to use for the alarm definitions repository
alarm_definitions_driver = monasca_api.common.repositories.sqla.alarm_definitions_repository:AlarmDefinitionsRepository

# The driver to use for the alarms repository
alarms_driver = monasca_api.common.repositories.sqla.alarms_repository:AlarmsRepository

# The driver to use for the notifications repository
notifications_driver = monasca_api.common.repositories.sqla.notifications_repository:NotificationsRepository

# The driver to use for the notification  method type repository
notification_method_type_driver = monasca_api.common.repositories.sqla.notification_method_type_repository:NotificationMethodTypeRepository


[dispatcher]
driver = v2_reference

[kafka]
# The endpoints to the kafka server
uri = kafka:{{.Values.monasca_kafka_port_internal}}

# The topic that metrics will be published too
metrics_topic = metrics

# consumer group name
group = api

# how many times to try when error occurs
max_retry = 1

# wait time between tries when kafka goes down
wait_time = 1

# use synchronous or asynchronous connection to kafka
async = False

# send messages in bulk or send messages one by one.
compact = True

# How many partitions this connection should listen messages on, this
# parameter is for reading from kafka. If listens on multiple partitions,
# For example, if the client should listen on partitions 1 and 3, then the
# configuration should look like the following:
#   partitions = 1
#   partitions = 3
# default to listen on partition 0.
partitions = 0

[influxdb]
# Only needed if Influxdb database is used for backend.
# The IP address of the InfluxDB service.
ip_address = {{.Values.monasca_influxdb_endpoint_host_internal}}

# The port number that the InfluxDB service is listening on.
port = {{.Values.monasca_influxdb_port_internal}}

# The username to authenticate with.
user = mon_api

# The password to authenticate with.
password = {{.Values.monasca_influxdb_monapi_password}}

# The name of the InfluxDB database to use.
database_name = mon

[cassandra]
# Only needed if Cassandra database is used for backend.
# Comma separated list of Cassandra node IP addresses. No spaces.
cluster_ip_addresses: 192.168.10.6
keyspace: monasca

# Below is configuration for database.
# The order of reading configuration for database is:
# 1) [mysql] section
# 2) [database]
#    url
# 3) [database]
#    host = 127.0.0.1
#    username = monapi
#    password = password
#    drivername = mysql+pymysql
#    port = 3306
#    database = mon
#    query = ""

#[mysql]
#database_name = mon
#hostname = {{.Values.monasca_mysql_endpoint_host_internal}}
#username = monapi
#password = {{.Values.monasca_mysql_monapi_password}}

[database]
url = "mysql+pymysql://monapi:{{.Values.monasca_mysql_monapi_password}}@{{.Values.monasca_mysql_endpoint_host_internal}}:{{.Values.monasca_mysql_port_internal}}/mon"

[keystone_authtoken]
auth_uri = {{.Values.keystone_api_endpoint_protocol_internal}}://{{.Values.keystone_api_endpoint_host_internal}}:{{.Values.keystone_api_port_internal}}
auth_url = {{.Values.keystone_api_endpoint_protocol_admin}}://{{.Values.keystone_api_endpoint_host_admin}}:{{.Values.keystone.api.port.admin}}/v3
auth_type = v3password
username = {{.Values.monasca_api_username}}
password = {{.Values.monasca_api_password}}
user_domain_name = {{.Values.monasca_api_project_domain_name}}
project_name = {{.Values.monasca_api_project_name}}
project_domain_name = {{.Values.monasca_api_project_domain_name}}
cafile = /etc/ssl/certs/ca-certificates.crt
certfile =
keyfile =
insecure = false
token_cache_time = 900
memcached_servers = 127.0.0.1:11211

{{ end }}
