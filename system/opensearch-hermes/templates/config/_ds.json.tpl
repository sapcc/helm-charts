{
  "index_patterns": [
    "hermes*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "4",
      "index.number_of_replicas": "1",
      "index.refresh_interval": "60s"
    },
    "aliases": {
      "hermes-ds": {}
    }
  },
  "composed_of": [],
  "priority": "0",
  "_meta": {
    "flow": "audit"
  },
  "data_stream": {
    "timestamp_field": {
      "name": "@timestamp"
    }
  }
}
