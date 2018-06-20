cluster.name: {{.Values.elk_elasticsearch_cluster_name}}

cloud:
  kubernetes:
    service: es-master
    namespace: {{.Values.elk_namespace}}

node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}

path:
  data: /data/data
  logs: /data/log

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.enabled: ${HTTP_ENABLE}
http.max_content_length: 500mb

discovery.zen.hosts_provider: kubernetes

discovery.zen.minimum_master_nodes: 2
