{
  "order": 0,
  "template": "httplogs-*",
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "3",
      "number_of_replicas": "1"
    }
  },
  "mappings": {},
  "aliases": {}
}
