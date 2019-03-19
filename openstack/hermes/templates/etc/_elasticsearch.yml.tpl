cluster.name: {{required ".Values.hermes_elasticsearch_cluster_name" .Values.hermes_elasticsearch_cluster_name}}

node.master: true
node.data: true

path.data: /data/data
path.logs: /data/logs
path.repo: /data/snapshots

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.enabled: true
http.max_content_length: 500mb

discovery.zen.minimum_master_nodes: 1
