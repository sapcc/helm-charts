{
  "index_patterns": [
    "_DS_NAME_-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "{{ .Values.global.data_stream.audit.number_of_shards }}",
      "index.number_of_replicas": "1",
      "index.append_only.enabled": true,
      "index.refresh_interval": "60s"
    },
    "aliases": {
      "_DS_NAME_-ds": {}
    },
    "mappings": {
      "properties": {
        "timestamp": {
          "path": "@timestamp",
          "type": "alias"
       }
      }
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
