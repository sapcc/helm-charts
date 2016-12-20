{{- define "monasca_agent_conf_d_kafka_consumer_yaml_tpl" -}}
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
        persister:
          - metrics
        logstash-persister:
          - transformed-log
        notification:
          - alarm-notifications
          - retry-notifications
          - alarm-state-transitions
          - {{.Values.monasca_topics_notifications_periodic_60}}
        thresh:
          - metrics
          - events
        logstash-metrics:
          - transformed-log
        logstash-persister:
          - transformed-log
        logstash-transformer:
          - log

{{ end }}
