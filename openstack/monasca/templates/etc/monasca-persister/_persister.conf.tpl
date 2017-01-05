{{- define "monasca_persister_persister_conf_tpl" -}}
[DEFAULT]
# Show debugging output in logs (sets DEBUG log level output)
{{if eq .Values.monasca_persister_loglevel "DEBUG" }}
general_log             = 1
{{else}}
general_log             = 0
{{end}}

[repositories]
# The driver to use for the metrics repository
metrics_driver = monasca_persister.repositories.influxdb.metrics_repository:MetricInfluxdbRepository

# The driver to use for the alarm state history repository
alarm_state_history_driver = monasca_persister.repositories.influxdb.alarm_state_history_repository:AlarmStateHistInfluxdbRepository

[zookeeper]
# Comma separated list of host:port
uri = zk:{{.Values.monasca_zookeeper_port_internal}}
partition_interval_recheck_seconds = 15

[kafka_alarm_history]
# number of workers
num_processors = 1
# Comma separated list of Kafka broker host:port.
uri = kafka:{{.Values.monasca_kafka_port_internal}}
group_id = persister
consumer_id = KAFKA_CONSUMER_ID
topic = alarm-state-transitions
database_batch_size = 5000
max_wait_time_seconds = 60
# The following 3 values are set to the kakfa-python defaults
fetch_size_bytes = 4096
buffer_size = 4096
# 8 times buffer size
max_buffer_size = 32768
# Path in zookeeper for kafka consumer group partitioning algo
zookeeper_path = /persister_partitions/alarm-state-transitions

[kafka_metrics]
# number of workers
num_processors = 1
# Comma separated list of Kafka broker host:port
uri = kafka:{{.Values.monasca_kafka_port_internal}}
group_id = persister
topic = metrics
consumer_id = {{.Values.kafka_consumer_id}}
client_id = {{.Values.kafka_client_id}}
database_batch_size = 5000
max_wait_time_seconds = 60
# The following 3 values are set to the kakfa-python defaults
fetch_size_bytes = 4096
buffer_size = 4096
# 8 times buffer size
max_buffer_size = 32768
# Path in zookeeper for kafka consumer group partitioning algo
zookeeper_path = /persister_partitions/metrics

[influxdb]
database_name = mon
ip_address = {{.Values.monasca_influxdb_endpoint_host_internal}}
port = {{.Values.monasca_influxdb_port_internal}}
user = mon_persister
password = {{.Values.monasca_influxdb_monpersister_password}}
{{ end }}
