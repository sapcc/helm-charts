{
  "order": 0,
  "template": ".monitoring-data-2",
  "settings": {
    "index": {
      "number_of_shards": "1",
      "codec": "best_compression",
      "number_of_replicas": "0"
    }
  },
  "mappings": {
    "_default_": {
      "enabled": false
    },
    "cluster_info": {
      "_meta": {
        "xpack.version": "5.3.2"
      },
      "enabled": false
    },
    "kibana": {
      "enabled": false
    },
    "node": {
      "enabled": false
    },
    "logstash": {
      "enabled": false
    }
  },
  "aliases": {}
}
