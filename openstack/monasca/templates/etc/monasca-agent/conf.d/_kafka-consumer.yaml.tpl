init_config:

instances:
  -   name: kafka
      dimensions:
        service: monitoring
        component: kafka
      kafka_connect_str: kafka:{{.Values.monasca_kafka_port_internal}}
      per_partition: False
      full_output: True
      consumer_groups:
        persister:
          - alarm-state-transitions
          - metrics
        notification:
          - alarm-notifications
          - retry-notifications
          - alarm-state-transitions
          - {{.Values.monasca_topics_notifications_periodic_60}}
        thresh:
          - metrics
          - events
        logstash-persister:
          - transformed-log
        logstash-metrics:
          - transformed-log
        logstash-transformer:
          - log
