cluster.name: {{.Values.elk_elasticsearch_cluster_name}}

#cloud.kubernetes.service: es-master
#cloud.kubernetes.namespace: {{.Values.elk_namespace}}

node.master: ${NODE_MASTER}
node.data: ${NODE_DATA}

path.data: /data/data
path.logs: /data/log

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.enabled: ${HTTP_ENABLE}
http.max_content_length: 500mb

#discovery.zen.hosts_provider: kubernetes
discovery.zen.ping.unicast.hosts: es-master
discovery.zen.minimum_master_nodes: 2

xpack.security.enabled: false
xpack.monitoring.enabled: false
