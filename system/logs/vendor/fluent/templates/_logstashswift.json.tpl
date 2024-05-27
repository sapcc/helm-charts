{
  "order": 0,
  "template": "logstash-swift-*",
  "settings": {
    "index": {
      "refresh_interval": "30s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "10",
      "number_of_replicas": "1",
      "mapping": {
        "total_fields": {
          "limit": "2000"
        }
      }
    }
  },
  "mappings": {},
  "aliases": {}
}
