{
  "order": 0,
  "template": "logstash-*",
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "{{ .Values.logstash_shards }}",
      "number_of_replicas": "1"
    }
  },
  "mappings": {  
    "mappings": {
      "_size": {
        "enabled": true
      }
    }
},
  "aliases": {}
}
