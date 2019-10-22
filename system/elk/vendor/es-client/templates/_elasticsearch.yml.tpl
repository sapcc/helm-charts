node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}


cluster.name: elkelasticsearch
node.name: ${NODE_NAME}

discovery.seed_hosts:
  {{- $replicas := .Values.global.master_replicas | int }}
  {{- range $i, $e := untilStep 0 $replicas 1 }}
    es-master-{{ $i }},
  {{- end }}

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
