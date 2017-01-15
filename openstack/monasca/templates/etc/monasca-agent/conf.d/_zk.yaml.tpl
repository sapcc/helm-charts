init_config:

instances:

- name: zk
  dimensions:
    service: monitoring
    component: zookeeper
  host: zk
  port: {{.Values.monasca_zookeeper_port_internal}}
  timeout: 3
