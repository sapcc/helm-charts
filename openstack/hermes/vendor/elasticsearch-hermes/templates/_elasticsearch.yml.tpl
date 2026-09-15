node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}


cluster.name: elasticsearch-hermes
cluster.initial_master_nodes:
  {{- $replicas := .Values.replicas | int }}
  {{- range $i, $e := untilStep 0 $replicas 1 }}
    elasticsearch-hermes-{{ $i }},
  {{- end }}
cluster.max_shards_per_node: 10000
action.search.shard_count.limit: 10000

path:
  data: /data/data
  logs: /data/log
  repo: /data/snapshots

network.host: 0.0.0.0
transport.host: 0.0.0.0
indices.breaker.total.use_real_memory: false
http.max_content_length: 1000mb
http.compression: true

discovery.seed_hosts: elasticsearch-hermes

xpack.ml.enabled: false
xpack.security.enabled: false
xpack.watcher.enabled: false
