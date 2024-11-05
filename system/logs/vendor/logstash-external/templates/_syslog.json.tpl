{
  "order": 0,
  "template": "syslog-*",
  "settings": {
    "index": {
      "refresh_interval": "60s",
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
