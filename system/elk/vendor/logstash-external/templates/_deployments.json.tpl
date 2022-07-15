{
  "order": 0,
  "index_patterns": [
    "deployments-*"
  ],
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "3",
      "number_of_replicas": "1",
      "mapping": {
        "total_fields": {
          "limit": "2500"
        }
      }
    }
  },
  "mappings": {},
  "aliases": {}
}
