cluster.name: {{required ".Values.hermes_elasticsearch_cluster_name" .Values.hermes_elasticsearch_cluster_name}}

node.master: true
node.data: true

path.data: /data/data
path.logs: /data/logs
path.repo: /data/snapshots

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.max_content_length: 1000mb
http.compression: true
cluster.max_shards_per_node: 10000
action.search.shard_count.limit: 10000

{% if .Values.elasticsearch.singleNode.enabled %}
discovery.type: {{ .Values.elasticsearch.singleNode.discoveryType }}
{% else %}
discovery.type: {{ .Values.elasticsearch.statefulSet.discoveryType }}
discovery.zen.minimum_master_nodes: {{ .Values.elasticsearch.statefulSet.minimumMasterNodes }}
{% endif %}

indices.breaker.total.use_real_memory: false

xpack.ml.enabled: false
xpack.security.enabled: false
xpack.watcher.enabled: false
