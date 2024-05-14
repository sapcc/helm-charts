{
  "order": 0,
  "template": "alerts-*",
  "settings": {
    "index": {
      "mapping": {
        "total_fields": {
          "limit": "4000"
        }
      },
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "1",
      "number_of_replicas": "1"
    }
  },
  "mappings": {},
  "aliases": {}
}
