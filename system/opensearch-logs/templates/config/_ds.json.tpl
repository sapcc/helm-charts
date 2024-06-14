{
  "index_patterns": [
    "DS_STREAM_NAME-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "1",
      "index.number_of_replicas": "1",
      "index.refresh_interval": "15s"
    },
    "aliases": {
      "DS_STREAM_NAME-ds": {}
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
