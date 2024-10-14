{
  "order": 0,
  "template": "storage-*",
  "settings": {
    "index": {
      "refresh_interval": "30s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "60m"
        }
      },
      "number_of_shards": "5",
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
