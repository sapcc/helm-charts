node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}


cluster.name: elasticsearch-hermes
cluster.initial_master_nodes:
  {{- $replicas := .Values.replicas | int }}
  {{- range $i, $e := untilStep 0 $replicas 1 }}
    elasticsearch-hermes-{{ $i }},
  {{- end }}

path:
  data: /data/data
  logs: /data/log

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.max_content_length: 500mb

discovery.seed_hosts: elasticsearch-hermes

xpack.ml.enabled: false
xpack.security.enabled: false
xpack.watcher.enabled: false
