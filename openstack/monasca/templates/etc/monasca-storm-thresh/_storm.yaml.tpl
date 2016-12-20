{{- define "monasca_storm_thresh_storm_yaml_tpl" -}}
### base
java.library.path: "/usr/local/lib:/opt/local/lib:/usr/lib"
storm.local.dir: "/var/storm"

### zookeeper.*
storm.zookeeper.servers:

  - zk

storm.zookeeper.port: {{.Values.monasca_zookeeper_port_internal}}
storm.zookeeper.retry.interval: 5000
storm.zookeeper.retry.times: 29
storm.zookeeper.root: /storm
storm.zookeeper.session.timeout: 15000

### supervisor.* configs are for node supervisors
supervisor.slots.ports:
    - 6701
    - 6702
    - 6703

supervisor.childopts: -Xmx512m

### worker.* configs are for task workers
worker.childopts: -Xmx512m -XX:+UseConcMarkSweepGC -Dcom.sun.management.jmxremote

### nimbus.* configs are for the master
nimbus.thrift.port: 6627
nimbus.childopts: -Xmx512m
nimbus.seeds: ["127.0.0.1"]

### ui.* configs are for the master
ui.port: 8088
ui.childopts: -Xmx768m

#log viewer
logviewer.port: 8000
logviewer.childopts: "-Xmx128m"
logviewer.cleanup.age.mins: 10080
logviewer.appender.name: "STDOUT"

logs.users: null

### drpc.* configs

### transactional.* configs
transactional.zookeeper.servers:

  - zk

transactional.zookeeper.port: {{.Values.monasca_zookeeper_port_internal}}
transactional.zookeeper.root: /storm-transactional

### topology.* configs are for specific executing storms
topology.acker.executors: 1
topology.debug: False
{{ end }}
