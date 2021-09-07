cluster.name: {{required ".Values.hermes_elasticsearch_cluster_name" .Values.hermes_elasticsearch_cluster_name}}

node.master: true
node.data: true

path.data: /data/data
path.logs: /data/logs
path.repo: /data/snapshots

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.max_content_length: 500mb
cluster.max_shards_per_node: 10000

discovery.zen.minimum_master_nodes: 1
discovery.type: single-node

xpack.ml.enabled: false
xpack.security.enabled: false
xpack.watcher.enabled: false
