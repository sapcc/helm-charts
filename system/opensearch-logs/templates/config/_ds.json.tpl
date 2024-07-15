{
  "index_patterns": [
    "_DS_NAME_-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "1",
      "index.number_of_replicas": "1",
      "index.refresh_interval": "15s"
    },
    "aliases": {
      "_DS_NAME_-ds": {}
    }
  },
  "composed_of": [],
  "priority": "0",
  "_meta": {
    "flow": "simple"
  },
  "data_stream": {
    "timestamp_field": {
      "name": "@timestamp"
    }
  }
}
