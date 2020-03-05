node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}


cluster.name: elkelasticsearch
node.name: ${NODE_NAME}

discovery.seed_hosts: es-master

path:
  data: /data/data
  logs: /data/log

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.max_content_length: 500mb


xpack.ml.enabled: false
xpack.security.enabled: false
xpack.monitoring.enabled: false
xpack.watcher.enabled: false
